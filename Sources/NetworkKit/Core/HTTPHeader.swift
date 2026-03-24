import Foundation

/// A name-value pair representing an HTTP header field.
public struct HTTPHeader: Sendable, Hashable {

    // MARK: - Properties

    public let name: String
    public let value: String

    // MARK: - Init

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    // MARK: - Static Factories

    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: value)
    }

    public static func bearerToken(_ token: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: "Bearer \(token)")
    }

    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept", value: value)
    }

    public static let jsonContent = HTTPHeader.contentType("application/json")
    public static let jsonAccept = HTTPHeader.accept("application/json")
}
