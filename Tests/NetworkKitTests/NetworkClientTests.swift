import XCTest
@testable import NetworkKit

final class NetworkClientTests: XCTestCase {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeClient(retryPolicy: RetryPolicy = .none) -> URLSessionClient {
        URLSessionClient(session: makeSession(), retryPolicy: retryPolicy)
    }

    // MARK: - Success

    func testSendDecodesResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            let json = Data("{\"id\":1,\"name\":\"Alice\"}".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let client = makeClient()
        let user: MockUser = try await client.send(MockEndpoint())

        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "Alice")
    }

    func testSendReturnsRawData() async throws {
        let expectedData = Data("raw-response".utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedData)
        }

        let client = makeClient()
        let data = try await client.send(MockEndpoint())

        XCTAssertEqual(data, expectedData)
    }

    // MARK: - Error Handling

    func testUnauthorizedThrowsError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = makeClient()

        do {
            let _: MockUser = try await client.send(MockEndpoint())
            XCTFail("Expected unauthorized error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServerErrorThrowsRequestFailed() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = makeClient()

        do {
            let _: MockUser = try await client.send(MockEndpoint())
            XCTFail("Expected request failed error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .requestFailed(statusCode: 500, data: Data()))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDecodingFailureThrowsError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("invalid-json".utf8))
        }

        let client = makeClient()

        do {
            let _: MockUser = try await client.send(MockEndpoint())
            XCTFail("Expected decoding error")
        } catch let error as NetworkError {
            if case .decodingFailed = error {
                // Expected
            } else {
                XCTFail("Expected decodingFailed, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Retry

    func testRetryOnServerError() async throws {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let statusCode = requestCount < 3 ? 503 : 200
            let data = requestCount < 3 ? Data() : Data("{\"id\":1,\"name\":\"Retry\"}".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let policy = RetryPolicy(
            maxRetryCount: 3,
            delay: .milliseconds(10),
            backoffMultiplier: 1.0
        )
        let client = makeClient(retryPolicy: policy)
        let user: MockUser = try await client.send(MockEndpoint())

        XCTAssertEqual(user.name, "Retry")
        XCTAssertEqual(requestCount, 3)
    }
}
