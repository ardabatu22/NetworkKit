import XCTest
@testable import NetworkKit

// MARK: - Mock Interceptors

private struct AuthInterceptor: RequestInterceptor {
    let token: String

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var modified = request
        modified.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return modified
    }
}

private struct LoggingResponseInterceptor: ResponseInterceptor {
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        data
    }
}

// MARK: - Tests

final class InterceptorTests: XCTestCase {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func testRequestInterceptorAddsAuthHeader() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer test-token"
            )

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"id\":1,\"name\":\"Test\"}".utf8))
        }

        let client = URLSessionClient(
            session: makeSession(),
            retryPolicy: .none,
            requestInterceptors: [AuthInterceptor(token: "test-token")]
        )

        let user: MockUser = try await client.send(MockEndpoint())
        XCTAssertEqual(user.id, 1)
    }

    func testResponseInterceptorProcessesData() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"id\":2,\"name\":\"Processed\"}".utf8))
        }

        let client = URLSessionClient(
            session: makeSession(),
            retryPolicy: .none,
            responseInterceptors: [LoggingResponseInterceptor()]
        )

        let user: MockUser = try await client.send(MockEndpoint())
        XCTAssertEqual(user.name, "Processed")
    }
}
