import Foundation

@MainActor
func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<200 {
        if condition() { return }
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(5))
    }
}
