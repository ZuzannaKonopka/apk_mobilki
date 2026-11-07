import Foundation

enum AppConfig {
    /// API słownika.
    static let onlineDictionaryBaseURL = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en")!

    /// Adres HTTPS serwera ćwiczeniowego
    static let practiceServerAddress = "https://home.agh.edu.pl/~ernst/zpsm/dictionary.php?word=cat&scenario=slow"
}
