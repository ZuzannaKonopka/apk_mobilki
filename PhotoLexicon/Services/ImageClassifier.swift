import Foundation

/// Abstrakcja klasyfikatora – w bloku 2 zastąpiona przez Core ML.
protocol ImageClassifying: Sendable {
    func classify(imageData: Data, using classifier: ClassifierID) async throws -> [RecognitionResult]
}

/// Atrapy: asynchroniczne oczekiwanie (Task.sleep reaguje na anulowanie) i stałe wyniki.
struct MockClassifier: ImageClassifying {
    func classify(
        imageData: Data, using classifier: ClassifierID
    ) async throws -> [RecognitionResult] {
        switch classifier {
        case .readyMade:
            try await Task.sleep(for: .seconds(1))
            return [RecognitionResult(label: "cat", confidence: 0.85),
                    RecognitionResult(label: "dog", confidence: 0.10)]
        case .custom:
            try await Task.sleep(for: .seconds(2))
            return [RecognitionResult(label: "forest", confidence: 0.75),
                    RecognitionResult(label: "mountain", confidence: 0.20)]
        case .converted:
            try await Task.sleep(for: .seconds(3))
            return [RecognitionResult(label: "bird", confidence: 0.70),
                    RecognitionResult(label: "cat", confidence: 0.25)]
        }
    }
}
