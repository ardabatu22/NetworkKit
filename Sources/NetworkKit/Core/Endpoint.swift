import Foundation

/// Describes an API endpoint with all information needed to build a request.
public protocol Endpoint: Sendable {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [HTTPHeader] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: (any Encodable & Sendable)? { get }
}

// MARK: - Default Implementations

public extension Endpoint {

    var headers: [HTTPHeader] { [] }

    var queryItems: [URLQueryItem]? { nil }

    var body: (any Encodable & Sendable)? { nil }
}
