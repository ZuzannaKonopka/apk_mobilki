import Foundation
import Observation

enum DictionaryState {
    case idle
    case loading(String)
    case loaded(LookupResult)
    case empty(String)
    case failed(String)
    case cancelled
}

/// Model stanu ekranu słownika.
@MainActor
@Observable
final class DictionaryModel {
    var query: String = ""
    private(set) var state: DictionaryState = .idle
    private(set) var currentWord: String?

    private let settings: AppSettings
    private var job: Task<Void, Never>?
    private var generation = 0

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Wejście na ekran: z etykietą wyniku (automatyczne wyszukanie) lub bez (ręczne wpisanie).
    func open(word: String?) {
        invalidate()
        state = .idle
        currentWord = nil
        query = word ?? ""
        if let word { search(word) }
    }

    func submit() {
        search(query)
    }

    func search(_ rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }

        query = word
        currentWord = word

        job?.cancel()
        generation += 1
        let requestID = generation

        // Migawka ustawień – obowiązuje do końca tego żądania.
        let service = DictionaryService(configuration: settings.dictionaryConfiguration)
        state = .loading(word) // poprzednia definicja znika

        job = Task {
            do {
                let result = try await service.lookup(word)
                try Task.checkCancellation()
                guard requestID == generation else { return }
                state = .loaded(result)
                job = nil
            } catch {
                guard requestID == generation else { return }
                job = nil
                if Task.isCancelled || isCancellationError(error) {
                    state = .cancelled
                } else if let dictionaryError = error as? DictionaryError {
                    switch dictionaryError {
                    case .notFound, .noDefinition:
                        state = .empty(word)
                    default:
                        state = .failed(dictionaryError.message)
                    }
                } else {
                    state = .failed("Nieoczekiwany błąd: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Ponowienie: aktualne hasło i bieżące ustawienia, nowe żądanie HTTP.
    func retry() {
        guard let currentWord else { return }
        search(currentWord)
    }

    func cancel() {
        guard isLoading else { return }
        invalidate()
        state = .cancelled
    }

    /// Opuszczenie ekranu słownika.
    func leave() {
        let wasLoading = isLoading
        invalidate()
        if wasLoading { state = .cancelled }
    }

    private func invalidate() {
        job?.cancel()
        job = nil
        generation += 1
    }
}
