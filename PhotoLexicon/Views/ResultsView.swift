import SwiftUI

enum DictionaryRoute: Hashable {
    /// nil – ręczne wpisywanie hasła.
    case lookup(word: String?)
}

struct ResultsView: View {
    let analysis: AnalysisModel
    @State private var path: [DictionaryRoute] = []
    @State private var dictionary: DictionaryModel

    init(analysis: AnalysisModel, settings: AppSettings) {
        self.analysis = analysis
        _dictionary = State(initialValue: DictionaryModel(settings: settings))
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink(value: DictionaryRoute.lookup(word: nil)) {
                        Label("Wyszukaj hasło ręcznie", systemImage: "character.book.closed")
                    }
                }

                if analysis.hasResults || analysis.isRunning {
                    ForEach(ClassifierID.allCases) { classifier in
                        Section(classifier.displayName) {
                            sectionContent(for: classifier)
                        }
                    }
                } else {
                    Section {
                        emptyState
                    }
                }
            }
            .navigationTitle("Wyniki")
            .navigationDestination(for: DictionaryRoute.self) { _ in
                DictionaryView(model: dictionary)
            }
        }
        // Wejście na ekran słownika i jego opuszczenie (a nie przełączenie zakładki).
        .onChange(of: path) { oldPath, newPath in
            if newPath.count > oldPath.count, case .lookup(let word)? = newPath.last {
                dictionary.open(word: word)
            } else if newPath.isEmpty {
                dictionary.leave()
            }
        }
    }

    @ViewBuilder
    private func sectionContent(for classifier: ClassifierID) -> some View {
        if let results = analysis.results[classifier] {
            ForEach(results) { result in
                NavigationLink(value: DictionaryRoute.lookup(word: result.label)) {
                    HStack {
                        Text(result.label)
                        Spacer()
                        Text(result.confidence.formatted(.percent.precision(.fractionLength(0))))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else if analysis.state == .running(classifier) {
            HStack(spacing: 8) {
                ProgressView()
                Text("Trwa analiza…")
            }
        } else {
            Label("Oczekuje na uruchomienie", systemImage: "clock")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if analysis.state == .cancelled {
            ContentUnavailableView(
                "Analiza anulowana",
                systemImage: "xmark.circle",
                description: Text("Uruchom analizę ponownie w zakładce Zdjęcie.")
            )
        } else {
            ContentUnavailableView(
                "Brak wyników",
                systemImage: "photo.badge.magnifyingglass",
                description: Text("Wybierz zdjęcie w zakładce Zdjęcie i naciśnij „Analizuj”. Możesz też wyszukać hasło ręcznie.")
            )
        }
    }
}
