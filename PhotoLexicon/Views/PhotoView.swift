import PhotosUI
import SwiftUI

struct PhotoView: View {
    @Bindable var analysis: AnalysisModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $analysis.pickerItem, matching: .images) {
                        Label("Wybierz zdjęcie", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)

                    preview

                    statusView
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        Button {
                            analysis.analyze()
                        } label: {
                            Label("Analizuj", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!analysis.canAnalyze)

                        Button(role: .cancel) {
                            analysis.cancelAnalysis()
                        } label: {
                            Label("Anuluj", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!analysis.isRunning)
                    }
                }
                .padding()
            }
            .navigationTitle("Zdjęcie")
        }
        .onChange(of: analysis.pickerItem) { _, newItem in
            analysis.selectImage(newItem)
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let image = analysis.previewImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Podgląd wybranego zdjęcia")
        } else if analysis.isLoadingImage {
            ProgressView("Wczytywanie zdjęcia…")
                .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            ContentUnavailableView(
                "Brak zdjęcia",
                systemImage: "photo",
                description: Text("Wybierz zdjęcie z biblioteki, aby rozpocząć analizę.")
            )
            .frame(minHeight: 200)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch analysis.state {
        case .idle:
            Text("Wybierz zdjęcie, aby rozpocząć.")
                .foregroundStyle(.secondary)
        case .loadingImage:
            HStack(spacing: 8) {
                ProgressView()
                Text("Wczytywanie zdjęcia…")
            }
        case .ready:
            Label("Zdjęcie gotowe do analizy", systemImage: "checkmark.circle")
        case .running(let classifier):
            HStack(spacing: 8) {
                ProgressView()
                Text("Trwa: \(classifier.displayName)")
            }
        case .completed:
            Label("Analiza zakończona", systemImage: "checkmark.seal")
                .foregroundStyle(.green)
        case .cancelled:
            Label("Analiza anulowana", systemImage: "xmark.circle")
                .foregroundStyle(.orange)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Brak zdjęcia") {
    PhotoView(analysis: AnalysisModel())
}

#Preview("Wczytywanie") {
    PhotoView(analysis: .preview(state: .loadingImage, withImage: false))
}

#Preview("Gotowe do analizy") {
    PhotoView(analysis: .preview(state: .ready))
}

#Preview("Analiza – model własny") {
    PhotoView(analysis: .preview(state: .running(.custom), finished: [.readyMade]))
}

#Preview("Zakończona") {
    PhotoView(analysis: .preview(state: .completed, finished: ClassifierID.allCases))
}

#Preview("Anulowana") {
    PhotoView(analysis: .preview(state: .cancelled))
}

#Preview("Błąd wczytania") {
    PhotoView(analysis: .preview(
        state: .failed("Nie udało się wczytać zdjęcia. Wybierz inny plik."),
        withImage: false))
}
