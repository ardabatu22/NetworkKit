import Foundation

/// Intercepts and modifies outgoing requests before they are sent.
///
/// Use this to inject authentication tokens, add common headers, or log requests.
public protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
