import Foundation

enum ClassifierID: String, CaseIterable, Identifiable, Sendable {
    case readyMade, custom, converted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .readyMade: "Model gotowy"
        case .custom: "Model własny"
        case .converted: "Model konwertowany"
        }
    }
}

struct RecognitionResult: Identifiable, Sendable {
    let id = UUID()
    let label: String
    /// Pewność w zakresie 0–1.
    let confidence: Double
}

enum AnalysisState: Equatable {
    case idle
    case loadingImage
    case ready
    case running(ClassifierID)
    case completed
    case cancelled
    case failed(String)
}
