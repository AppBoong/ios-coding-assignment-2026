import Foundation

enum ErrorMessageFormatter {
    static func message(for error: any Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "잠시 후 다시 시도해 주세요"
        }
        switch networkError {
        case .transport:
            return "네트워크 연결을 확인해 주세요"
        case .notFound:
            return "상품을 찾을 수 없습니다"
        case .serverError:
            return "서버에 문제가 발생했습니다"
        case .decoding:
            return "데이터를 불러오지 못했습니다"
        case .requestTimeout:
            return "응답이 늦어지고 있습니다. 다시 시도해 주세요"
        default:
            return "잠시 후 다시 시도해 주세요"
        }
    }
}
