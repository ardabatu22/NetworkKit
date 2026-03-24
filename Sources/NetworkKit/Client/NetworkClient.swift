import Foundation

/// The main networking interface for sending requests and decoding responses.
public protocol NetworkClient: Sendable {
    /// Sends a request and decodes the response into the specified type.
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T

    /// Sends a request and returns raw response data.
    func send(_ endpoint: Endpoint) async throws -> Data
}
