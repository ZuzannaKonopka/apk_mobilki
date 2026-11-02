import SwiftUI

struct DictionaryView: View {
    @Bindable var model: DictionaryModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                searchBar
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Słownik")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("Hasło po angielsku, np. cat", text: $model.query)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { model.submit() }

            Button("Szukaj") { model.submit() }
                .buttonStyle(.borderedProminent)
                .disabled(model.trimmedQuery.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle:
            ContentUnavailableView(
                "Wpisz hasło",
                systemImage: "character.book.closed",
                description: Text("Wpisz angielskie słowo i naciśnij „Szukaj”.")
            )

        case .loading(let word):
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Pobieranie definicji hasła „\(word)”…")
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Anuluj", role: .cancel) { model.cancel() }
                    .buttonStyle(.bordered)
            }

        case .loaded(let result):
            VStack(alignment: .leading, spacing: 12) {
                Text(result.word)
                    .font(.largeTitle.bold())
                Text(result.definition)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                Divider()
                LabeledContent("Pobrano", value: result.fetchedAt.formatted())
                LabeledContent("Rozmiar odpowiedzi", value: "\(result.byteCount.formatted()) B")
            }

        case .empty(let word):
            message(
                title: "Brak definicji",
                systemImage: "questionmark.circle",
                description: "Słownik nie zawiera definicji hasła „\(word)”."
            )

        case .failed(let text):
            message(
                title: "Nie udało się pobrać definicji",
                systemImage: "exclamationmark.triangle",
                description: text
            )

        case .cancelled:
            message(
                title: "Pobieranie anulowane",
                systemImage: "xmark.circle",
                description: "Wyszukiwanie zostało przerwane."
            )
        }
    }

    private func message(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: 12) {
            ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
            if model.currentWord != nil {
                Button("Ponów") { model.retry() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
