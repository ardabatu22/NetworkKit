import Foundation

/// Intercepts and processes responses before they are returned to the caller.
///
/// Use this for logging, response transformation, or error handling middleware.
public protocol ResponseInterceptor: Sendable {
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data
}
