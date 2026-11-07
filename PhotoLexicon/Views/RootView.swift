import SwiftUI

struct RootView: View {
    let analysis: AnalysisModel
    let settings: AppSettings

    var body: some View {
        TabView {
            PhotoView(analysis: analysis)
                .tabItem { Label("Zdjęcie", systemImage: "photo") }

            ResultsView(analysis: analysis, settings: settings)
                .tabItem { Label("Wyniki", systemImage: "list.bullet.rectangle") }

            SettingsView(settings: settings)
                .tabItem { Label("Ustawienia", systemImage: "gearshape") }
        }
    }
}

#Preview("Cała aplikacja") {
    RootView(analysis: AnalysisModel(), settings: AppSettings())
}

#Preview("Aplikacja z wynikami") {
    RootView(
        analysis: .preview(state: .completed, finished: ClassifierID.allCases),
        settings: AppSettings())
}