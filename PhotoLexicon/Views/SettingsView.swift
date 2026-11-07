import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Źródło", selection: $settings.source) {
                        ForEach(DictionarySource.allCases) { source in
                            Text(source.title).tag(source)
                        }
                    }

                    if settings.source == .practice {
                        Picker("Scenariusz", selection: $settings.scenario) {
                            ForEach(TestScenario.allCases) { scenario in
                                Text(scenario.rawValue).tag(scenario)
                            }
                        }

                        if AppConfig.practiceServerAddress.isEmpty {
                            Label("Adres serwera ćwiczeniowego nie jest ustawiony w AppConfig.",
                                  systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Słownik")
                } footer: {
                    Text("Zmiana dotyczy następnego wyszukiwania lub ponowienia, nie trwającego żądania.")
                }

                Section("Forma zwracania się") {
                    Picker("Forma", selection: $settings.addressForm) {
                        ForEach(AddressForm.allCases) { form in
                            Text(form.title).tag(form)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Ustawienia")
        }
    }
}

#Preview("Słownik online") {
    SettingsView(settings: AppSettings())
}

#Preview("Serwer ćwiczeniowy") {
    let settings = AppSettings()
    settings.source = .practice
    settings.scenario = .slow
    return SettingsView(settings: settings)
}