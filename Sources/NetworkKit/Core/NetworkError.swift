import Foundation

/// Typed errors returned by NetworkKit.
public enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case requestFailed(statusCode: Int, data: Data?)
    case decodingFailed(String)
    case noData
    case unauthorized
    case timeout
    case noConnection
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .requestFailed(let statusCode, _):
            return "Request failed with status code \(statusCode)."
        case .decodingFailed(let message):
            return "Failed to decode response: \(message)"
        case .noData:
            return "No data received from the server."
        case .unauthorized:
            return "Authentication required or session expired."
        case .timeout:
            return "The request timed out."
        case .noConnection:
            return "No internet connection available."
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}

extension NetworkError: Equatable {

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.unauthorized, .unauthorized),
             (.timeout, .timeout),
             (.noConnection, .noConnection):
            return true
        case (.requestFailed(let lCode, let lData), .requestFailed(let rCode, let rData)):
            return lCode == rCode && lData == rData
        case (.decodingFailed(let lMsg), .decodingFailed(let rMsg)):
            return lMsg == rMsg
        case (.unknown(let lMsg), .unknown(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}
