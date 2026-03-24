import XCTest
@testable import NetworkKit

final class RequestBuilderTests: XCTestCase {

    private var builder: RequestBuilder!

    override func setUp() {
        super.setUp()
        builder = RequestBuilder()
    }

    func testBuildGETRequest() throws {
        let endpoint = MockEndpoint()
        let request = try builder.build(from: endpoint)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/test")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
    }

    func testBuildRequestWithQueryItems() throws {
        var endpoint = MockEndpoint()
        endpoint.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "20")
        ]

        let request = try builder.build(from: endpoint)
        let url = request.url?.absoluteString ?? ""

        XCTAssertTrue(url.contains("page=1"))
        XCTAssertTrue(url.contains("limit=20"))
    }

    func testBuildRequestWithHeaders() throws {
        var endpoint = MockEndpoint()
        endpoint.headers = [
            .bearerToken("test-token"),
            .jsonAccept
        ]

        let request = try builder.build(from: endpoint)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testBuildPOSTRequestWithBody() throws {
        var endpoint = MockEndpoint()
        endpoint.method = .post
        endpoint.body = MockUser(id: 1, name: "Test")

        let request = try builder.build(from: endpoint)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testBuildRequestWithCustomContentType() throws {
        var endpoint = MockEndpoint()
        endpoint.method = .post
        endpoint.headers = [.contentType("text/plain")]
        endpoint.body = MockUser(id: 1, name: "Test")

        let request = try builder.build(from: endpoint)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "text/plain")
    }
}
