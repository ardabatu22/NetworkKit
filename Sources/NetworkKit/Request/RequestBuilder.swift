import Foundation

/// Converts an `Endpoint` into a fully configured `URLRequest`.
public struct RequestBuilder: Sendable {

    // MARK: - Properties

    private let encoder: JSONEncoder

    // MARK: - Init

    public init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
    }

    // MARK: - Public Methods

    /// Builds a `URLRequest` from the given endpoint.
    public func build(from endpoint: Endpoint) throws -> URLRequest {
        let url = try buildURL(from: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setHeaders(endpoint.headers)

        if let body = endpoint.body {
            request.httpBody = try encodeBody(body)
            if !endpoint.headers.contains(where: { $0.name == "Content-Type" }) {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }

    // MARK: - Private Methods

    private func buildURL(from endpoint: Endpoint) throws -> URL {
        var components = URLComponents(url: endpoint.baseURL, resolvingAgainstBaseURL: true)
        let basePath = components?.path ?? ""
        components?.path = basePath + endpoint.path
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        return url
    }

    private func encodeBody(_ body: any Encodable) throws -> Data {
        do {
            return try encoder.encode(AnyEncodable(body))
        } catch {
            throw NetworkError.decodingFailed("Failed to encode request body: \(error.localizedDescription)")
        }
    }
}

// MARK: - AnyEncodable

/// Type-erased `Encodable` wrapper.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
