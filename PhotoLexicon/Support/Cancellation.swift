import Foundation

/// Czy błąd oznacza anulowanie zadania (Swift Concurrency lub URLSession).
func isCancellationError(_ error: any Error) -> Bool {
    if error is CancellationError { return true }
    if let urlError = error as? URLError, urlError.code == .cancelled { return true }
    return false
}
