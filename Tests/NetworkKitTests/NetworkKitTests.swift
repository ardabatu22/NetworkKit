import XCTest
@testable import NetworkKit

final class MultipartFormDataTests: XCTestCase {

    func testAddFieldAndEncode() {
        var form = MultipartFormData(boundary: "test-boundary")
        form.addField(name: "username", value: "alice")

        let data = form.encode()
        let string = String(data: data, encoding: .utf8) ?? ""

        XCTAssertTrue(string.contains("--test-boundary"))
        XCTAssertTrue(string.contains("name=\"username\""))
        XCTAssertTrue(string.contains("alice"))
        XCTAssertTrue(string.contains("--test-boundary--"))
    }

    func testAddFileAndEncode() {
        var form = MultipartFormData(boundary: "test-boundary")
        let fileData = Data("file-content".utf8)
        form.addFile(name: "avatar", data: fileData, fileName: "photo.jpg", mimeType: "image/jpeg")

        let data = form.encode()
        let string = String(data: data, encoding: .utf8) ?? ""

        XCTAssertTrue(string.contains("filename=\"photo.jpg\""))
        XCTAssertTrue(string.contains("Content-Type: image/jpeg"))
        XCTAssertTrue(string.contains("file-content"))
    }

    func testContentTypeIncludesBoundary() {
        let form = MultipartFormData(boundary: "my-boundary")
        XCTAssertEqual(form.contentType, "multipart/form-data; boundary=my-boundary")
    }
}
