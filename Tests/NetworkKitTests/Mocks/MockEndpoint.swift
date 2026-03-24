import Foundation
@testable import NetworkKit

struct MockEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.example.com")!
    var path: String = "/test"
    var method: HTTPMethod = .get
    var headers: [HTTPHeader] = []
    var queryItems: [URLQueryItem]?
    var body: (any Encodable & Sendable)?
}

struct MockUser: Codable, Equatable, Sendable {
    let id: Int
    let name: String
}
