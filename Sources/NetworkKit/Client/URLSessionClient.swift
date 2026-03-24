import Foundation

/// A concrete `NetworkClient` implementation backed by `URLSession`.
public final class URLSessionClient: NetworkClient, @unchecked Sendable {

    // MARK: - Properties

    private let session: URLSession
    private let requestBuilder: RequestBuilder
    private let decoder: JSONDecoder
    private let retryPolicy: RetryPolicy
    private let requestInterceptors: [any RequestInterceptor]
    private let responseInterceptors: [any ResponseInterceptor]

    // MARK: - Init

    public init(
        session: URLSession = .shared,
        requestBuilder: RequestBuilder = RequestBuilder(),
        decoder: JSONDecoder = JSONDecoder(),
        retryPolicy: RetryPolicy = .default,
        requestInterceptors: [any RequestInterceptor] = [],
        responseInterceptors: [any ResponseInterceptor] = []
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.decoder = decoder
        self.retryPolicy = retryPolicy
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
    }

    // MARK: - NetworkClient

    public func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await send(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    public func send(_ endpoint: Endpoint) async throws -> Data {
        var request = try requestBuilder.build(from: endpoint)

        for interceptor in requestInterceptors {
            request = try await interceptor.intercept(request)
        }

        return try await performRequest(request, attempt: 0)
    }

    // MARK: - Private Methods

    private func performRequest(_ request: URLRequest, attempt: Int) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown("Invalid response type")
            }

            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }

            if !(200..<300).contains(httpResponse.statusCode) {
                if attempt < retryPolicy.maxRetryCount,
                   retryPolicy.shouldRetry(statusCode: httpResponse.statusCode) {
                    try await Task.sleep(for: retryPolicy.delay(for: attempt))
                    return try await performRequest(request, attempt: attempt + 1)
                }
                throw NetworkError.requestFailed(statusCode: httpResponse.statusCode, data: data)
            }

            var processedData = data
            for interceptor in responseInterceptors {
                processedData = try await interceptor.intercept(httpResponse, data: processedData)
            }

            return processedData
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            if attempt < retryPolicy.maxRetryCount {
                let isRetryable = error.code == .timedOut
                    || error.code == .networkConnectionLost
                    || error.code == .notConnectedToInternet
                if isRetryable {
                    try await Task.sleep(for: retryPolicy.delay(for: attempt))
                    return try await performRequest(request, attempt: attempt + 1)
                }
            }
            throw mapURLError(error)
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
