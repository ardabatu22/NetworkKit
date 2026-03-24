import Foundation

extension Data {

    /// Returns a pretty-printed JSON string for debugging, or a byte-count fallback.
    var prettyJSON: String {
        guard
            let object = try? JSONSerialization.jsonObject(with: self),
            let pretty = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
            let string = String(data: pretty, encoding: .utf8)
        else {
            return "[\(count) bytes]"
        }
        return string
    }
}
