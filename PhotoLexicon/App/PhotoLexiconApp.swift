import SwiftUI

@main
struct PhotoLexiconApp: App {
    // Jedna instancja modelu analizy i ustawień dla całej aplikacji.
    @State private var analysis = AnalysisModel()
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView(analysis: analysis, settings: settings)
        }
    }
}
