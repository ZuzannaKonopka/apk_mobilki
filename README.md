# PhotoLexicon – ZPSM 2026/2027, część iOS

Aplikacja wczytuje zdjęcie, pokazuje wyniki trzech klasyfikatorów (w bloku 1 atrapy) i pobiera definicję hasła ze słownika internetowego.

## Środowisko

- macOS z Xcode 16 lub nowszym
- iOS Deployment Target: 17.0
- Swift 6, Default Actor Isolation = nonisolated; kontrola współbieżności włączona
- SwiftUI, Observation, PhotosUI, URLSession – bez zewnętrznych bibliotek

## Uruchomienie

1. Sklonuj repozytorium i wybierz tag `blok-1`.
2. Otwórz `PhotoLexicon.xcodeproj`.
3. Wybierz symulator iPhone i uruchom (⌘R). Zdjęcia do testów przeciągnij do aplikacji Zdjęcia w symulatorze.

## Struktura

- `Views/` – widoki SwiftUI (zakładki Zdjęcie, Wyniki, Ustawienia; ekran Słownik)
- `Models/` – `AnalysisModel` (wspólny, `@MainActor @Observable`), `DictionaryModel`, `AppSettings`
- `Services/` – `MockClassifier` (protokół `ImageClassifying`), `DictionaryService`

## Wyniki prób

1. Zdjęcie i wyniki: bez zdjęcia „Analizuj” jest nieaktywny; po wyborze widać podgląd, po analizie trzy sekcje z etykietami i procentami, a ponowna analiza zastępuje wyniki bez dublowania.
2. Responsywność: podczas analizy i scenariusza slow można przełączać zakładki, przewijać i obsługiwać kontrolki – UI reaguje na bieżąco.
3. Anulowanie analizy: po anulowaniu w trakcie modelu własnego wyniki znikają, pojawia się „Analiza anulowana” i nic nie wraca po odczekaniu; ponowne uruchomienie działa.
4. Nowe zdjęcie: wybór zdjęcia B w trakcie analizy A usuwa wyniki A, które już nie wracają; szybki wybór kolejnych zdjęć pokazuje tylko ostatnie.
5. Prawdziwy słownik: dla „cat” wyświetla się definicja, czas pobrania i dodatni rozmiar odpowiedzi w bajtach.
6. Odpowiedzi kontrolowane: success – definicja, missing i empty – „Brak definicji”, server-error – błąd HTTP 500, invalid-json – błąd danych, slow – definicja po ok. 3 s, timeout – komunikat o przekroczeniu czasu; po zmianie na success „Ponów” pokazuje definicję.
7. Spóźniona odpowiedź: po wyszukaniu „swift” (slow) i szybkim wyszukaniu „actor” (success) po upływie 3 s nadal widoczny jest „actor”.
8. Anulowanie słownika: po anulowaniu slow, a także po wyjściu z ekranu szczegółów, wynik nie wraca po czasie odpowiedzi.
9. Brak połączenia: po odłączeniu sieci aplikacja kończy oczekiwanie komunikatem o połączeniu lub czasie, a po przywróceniu sieci „Ponów” pobiera definicję.
