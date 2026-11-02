import Foundation
import Observation

enum DictionarySource: String, CaseIterable, Identifiable, Sendable {
    case online, practice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .online: "Słownik online"
        case .practice: "Serwer ćwiczeniowy"
        }
    }
}

enum TestScenario: String, CaseIterable, Identifiable, Sendable {
    case success
    case missing
    case serverError = "server-error"
    case invalidJSON = "invalid-json"
    case empty
    case slow
    case timeout

    var id: String { rawValue }
}

enum AddressForm: String, CaseIterable, Identifiable, Sendable {
    case feminine, masculine, neutral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feminine: "Żeńska"
        case .masculine: "Męska"
        case .neutral: "Neutralna"
        }
    }
}

/// Migawka ustawień zapamiętywana przy rozpoczęciu żądania.
struct DictionaryConfiguration: Sendable, Equatable {
    let source: DictionarySource
    let scenario: TestScenario
}

/// Ustawienia przechowywane tylko w pamięci.
@MainActor
@Observable
final class AppSettings {
    var source: DictionarySource = .online
    var scenario: TestScenario = .success
    var addressForm: AddressForm = .neutral

    var dictionaryConfiguration: DictionaryConfiguration {
        DictionaryConfiguration(source: source, scenario: scenario)
    }
}
