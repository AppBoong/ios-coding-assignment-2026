import SwiftUI

struct ErrorRetryView: View {
    private static let spacing: CGFloat = 12

    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Self.spacing) {
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("다시 시도", action: retry)
                .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ErrorRetryView(message: "네트워크 연결을 확인해 주세요", retry: {})
}
