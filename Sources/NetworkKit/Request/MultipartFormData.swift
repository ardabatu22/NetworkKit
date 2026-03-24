import Foundation

/// Builds multipart/form-data request bodies for file uploads.
public struct MultipartFormData: Sendable {

    // MARK: - Types

    /// A single part in a multipart form body.
    public struct Part: Sendable {
        let name: String
        let data: Data
        let fileName: String?
        let mimeType: String?

        public init(name: String, data: Data, fileName: String? = nil, mimeType: String? = nil) {
            self.name = name
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }

    // MARK: - Properties

    public let boundary: String
    private var parts: [Part]

    /// The `Content-Type` header value including the boundary.
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    // MARK: - Init

    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
        self.parts = []
    }

    // MARK: - Public Methods

    /// Adds a text field to the form data.
    public mutating func addField(name: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        parts.append(Part(name: name, data: data))
    }

    /// Adds a file part to the form data.
    public mutating func addFile(name: String, data: Data, fileName: String, mimeType: String) {
        parts.append(Part(name: name, data: data, fileName: fileName, mimeType: mimeType))
    }

    /// Encodes all parts into the final multipart body `Data`.
    public func encode() -> Data {
        var body = Data()

        for part in parts {
            body.append("--\(boundary)\r\n")

            if let fileName = part.fileName, let mimeType = part.mimeType {
                body.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fileName)\"\r\n")
                body.append("Content-Type: \(mimeType)\r\n\r\n")
            } else {
                body.append("Content-Disposition: form-data; name=\"\(part.name)\"\r\n\r\n")
            }

            body.append(part.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        return body
    }
}

// MARK: - Data + String Append

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
