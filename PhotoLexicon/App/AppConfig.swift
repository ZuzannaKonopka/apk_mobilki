import Foundation

enum AppConfig {
    /// Prawdziwe API słownika.
    static let onlineDictionaryBaseURL = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en")!

    /// Adres HTTPS serwera ćwiczeniowego podany przez prowadzącego,
    /// np. "https://adres-od-prowadzacego/dictionary.php".
    /// Parametry word i scenario są dodawane przez URLQueryItem.
    static let practiceServerAddress = ""
}
