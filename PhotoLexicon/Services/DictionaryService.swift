import Foundation

struct Entry: Decodable, Sendable {
    let word: String
    let meanings: [Meaning]

    struct Meaning: Decodable, Sendable {
        let definitions: [Definition]
    }

    struct Definition: Decodable, Sendable {
        let definition: String
    }
}

struct LookupResult: Sendable {
    let word: String
    let definition: String
    let byteCount: Int
    let fetchedAt: Date
}

enum DictionaryError: Error, Equatable, Sendable {
    case notConfigured
    case invalidURL
    case invalidResponse
    case notFound
    case noDefinition
    case httpStatus(Int)
    case invalidData
    case timedOut
    case connection(String)

    var message: String {
        switch self {
        case .notConfigured:
            "Nie ustawiono adresu serwera ćwiczeniowego (AppConfig.practiceServerAddress)."
        case .invalidURL:
            "Nie udało się zbudować adresu zapytania."
        case .invalidResponse:
            "Serwer zwrócił nieprawidłową odpowiedź."
        case .notFound, .noDefinition:
            "Brak definicji."
        case .httpStatus(let code):
            "Błąd serwera (HTTP \(code)). Spróbuj ponownie."
        case .invalidData:
            "Serwer zwrócił niepoprawne dane (JSON o niezgodnej strukturze)."
        case .timedOut:
            "Przekroczono czas oczekiwania na odpowiedź serwera."
        case .connection:
            "Brak połączenia z serwerem. Sprawdź połączenie z internetem."
        }
    }
}

/// Usługa słownika. Konfiguracja (źródło i scenariusz) jest stała dla instancji.
struct DictionaryService: Sendable {
    let configuration: DictionaryConfiguration

    /// Własna sesja – bez zmiany URLSession.shared.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 8
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    init(configuration: DictionaryConfiguration) {
        self.configuration = configuration
    }

    func lookup(_ word: String) async throws -> LookupResult {
        let url = try makeURL(for: word)
        return try await fetch(url: url, word: word)
    }

    // MARK: - Budowanie adresu

    func makeURL(for word: String) throws -> URL {
        switch configuration.source {
        case .online:
            return AppConfig.onlineDictionaryBaseURL.appendingPathComponent(word)
        case .practice:
            let address = AppConfig.practiceServerAddress
            guard !address.isEmpty else { throw DictionaryError.notConfigured }
            guard var components = URLComponents(string: address) else {
                throw DictionaryError.invalidURL
            }
            components.queryItems = [
                URLQueryItem(name: "word", value: word),
                URLQueryItem(name: "scenario", value: configuration.scenario.rawValue)
            ]
            guard let url = components.url else { throw DictionaryError.invalidURL }
            return url
        }
    }

    // MARK: - Wspólne pobieranie, status i dekodowanie

    private func fetch(url: URL, word: String) async throws -> LookupResult {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let received: (Data, URLResponse)
        do {
            received = try await Self.session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .cancelled:
                throw CancellationError()
            case .timedOut:
                throw DictionaryError.timedOut
            default:
                throw DictionaryError.connection(error.localizedDescription)
            }
        }
        try Task.checkCancellation()

        let (data, response) = received
        guard let http = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }

        // Status sprawdzany przed dekodowaniem.
        switch http.statusCode {
        case 200..<300:
            break
        case 404:
            throw DictionaryError.notFound
        default:
            throw DictionaryError.httpStatus(http.statusCode)
        }

        let entries: [Entry]
        do {
            entries = try JSONDecoder().decode([Entry].self, from: data)
        } catch {
            throw DictionaryError.invalidData
        }

        let definition = entries
            .flatMap(\.meanings)
            .flatMap(\.definitions)
            .map(\.definition)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let definition else { throw DictionaryError.noDefinition }

        return LookupResult(
            word: entries.first?.word ?? word,
            definition: definition,
            byteCount: data.count,
            fetchedAt: Date()
        )
    }
}
