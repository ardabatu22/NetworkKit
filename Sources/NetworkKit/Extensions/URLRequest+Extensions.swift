import Foundation

extension URLRequest {

    /// Sets all headers from an array of `HTTPHeader` values.
    mutating func setHeaders(_ headers: [HTTPHeader]) {
        for header in headers {
            setValue(header.value, forHTTPHeaderField: header.name)
        }
    }
}
