import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

/// Wspólny model stanu analizy, utworzony raz przy korzeniu aplikacji.
@MainActor
@Observable
final class AnalysisModel {
    /// Element wybrany w PhotosPicker.
    var pickerItem: PhotosPickerItem?

    private(set) var imageData: Data?
    private(set) var previewImage: UIImage?
    private(set) var state: AnalysisState = .idle
    private(set) var results: [ClassifierID: [RecognitionResult]] = [:]

    private let classifier: any ImageClassifying

    private var imageJob: Task<Void, Never>?
    private var imageGeneration = 0
    private var analysisJob: Task<Void, Never>?
    private var analysisGeneration = 0

    init(classifier: any ImageClassifying = MockClassifier()) {
        self.classifier = classifier
    }

    // MARK: - Stan pochodny

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isLoadingImage: Bool { state == .loadingImage }

    var canAnalyze: Bool {
        imageData != nil && !isRunning && !isLoadingImage
    }

    var hasResults: Bool { !results.isEmpty }

    // MARK: - Wczytywanie zdjęcia

    /// Wywoływane po wybraniu nowego elementu. Anulowanie pickera nie zmienia
    /// wyboru, więc dotychczasowe zdjęcie pozostaje.
    func selectImage(_ item: PhotosPickerItem?) {
        guard let item else { return }

        // Unieważnij analizę.
        analysisJob?.cancel()
        analysisJob = nil
        analysisGeneration += 1
        results = [:]

        // Unieważnij poprzednie wczytywanie.
        imageJob?.cancel()
        imageGeneration += 1
        let loadID = imageGeneration

        imageData = nil
        previewImage = nil
        state = .loadingImage

        imageJob = Task {
            do {
                let data = try await item.loadTransferable(type: Data.self)
                try Task.checkCancellation()
                guard loadID == imageGeneration else { return }

                guard let data, let image = UIImage(data: data) else {
                    state = .failed("Nie udało się wczytać zdjęcia. Wybierz inny plik.")
                    imageJob = nil
                    return
                }
                imageData = data
                previewImage = image
                state = .ready
                imageJob = nil
            } catch {
                guard loadID == imageGeneration else { return }
                imageJob = nil
                if isCancellationError(error) {
                    state = .idle
                } else {
                    state = .failed("Błąd wczytywania zdjęcia: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Analiza

    func analyze() {
        guard canAnalyze, let data = imageData else { return }

        analysisJob?.cancel()
        analysisGeneration += 1
        let runID = analysisGeneration
        results = [:]
        let classifier = self.classifier

        analysisJob = Task {
            do {
                for id in ClassifierID.allCases {
                    guard runID == analysisGeneration else { return }
                    state = .running(id)

                    let output = try await classifier.classify(imageData: data, using: id)
                    try Task.checkCancellation()
                    guard runID == analysisGeneration else { return }
                    results[id] = output
                }
                guard runID == analysisGeneration else { return }
                state = .completed
                analysisJob = nil
            } catch {
                guard runID == analysisGeneration else { return }
                analysisJob = nil
                results = [:]
                if Task.isCancelled || isCancellationError(error) {
                    state = .cancelled
                } else {
                    state = .failed("Błąd analizy: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelAnalysis() {
        guard isRunning else { return }
        analysisJob?.cancel()
        analysisJob = nil
        analysisGeneration += 1
        results = [:]
        state = .cancelled
    }

    /// Pełne wyzerowanie – unieważnia wszystkie operacje.
    func reset() {
        imageJob?.cancel()
        analysisJob?.cancel()
        imageJob = nil
        analysisJob = nil
        imageGeneration += 1
        analysisGeneration += 1
        pickerItem = nil
        imageData = nil
        previewImage = nil
        results = [:]
        state = .idle
    }
}
