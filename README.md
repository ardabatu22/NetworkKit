# NetworkKit

A lightweight, generic async/await networking library for Swift. Built as a Swift Package with protocol-oriented design, interceptor support, and configurable retry logic.

## Features

- **Async/Await** — Modern concurrency, no completion handlers
- **Protocol-Oriented** — Define endpoints as types, swap implementations easily
- **Interceptors** — Request & response middleware (auth tokens, logging, etc.)
- **Retry Policy** — Configurable exponential backoff for transient failures
- **Multipart Upload** — Built-in multipart/form-data support
- **Type-Safe Errors** — Strongly typed `NetworkError` enum
- **Sendable** — Full Swift concurrency safety

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+

## Installation

Add NetworkKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/NetworkKit.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["NetworkKit"]
)
```

## Usage

### Define an Endpoint

```swift
import NetworkKit

struct GetUsersEndpoint: Endpoint {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var method: HTTPMethod { .get }
    var headers: [HTTPHeader] { [.jsonAccept] }
    var queryItems: [URLQueryItem]? {
        [URLQueryItem(name: "page", value: "1")]
    }
}
```

### Send a Request

```swift
let client = URLSessionClient()

// Decode into a model
let users: [User] = try await client.send(GetUsersEndpoint())

// Or get raw data
let data = try await client.send(GetUsersEndpoint())
```

### POST with Body

```swift
struct CreateUserEndpoint: Endpoint {
    let user: User

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var method: HTTPMethod { .post }
    var headers: [HTTPHeader] { [.jsonContent, .jsonAccept] }
    var body: (any Encodable & Sendable)? { user }
}

let newUser: User = try await client.send(CreateUserEndpoint(user: user))
```

### Add Authentication via Interceptor

```swift
struct AuthInterceptor: RequestInterceptor {
    let token: String

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

let client = URLSessionClient(
    requestInterceptors: [AuthInterceptor(token: "your-token")]
)
```

### Configure Retry Policy

```swift
let client = URLSessionClient(
    retryPolicy: RetryPolicy(
        maxRetryCount: 3,
        delay: .seconds(1),
        backoffMultiplier: 2.0,
        retryableStatusCodes: [500, 502, 503]
    )
)
```

### Multipart File Upload

```swift
var form = MultipartFormData()
form.addField(name: "description", value: "Profile photo")
form.addFile(name: "avatar", data: imageData, fileName: "photo.jpg", mimeType: "image/jpeg")

let body = form.encode()
```

### Error Handling

```swift
do {
    let user: User = try await client.send(endpoint)
} catch NetworkError.unauthorized {
    // Handle 401
} catch NetworkError.requestFailed(let statusCode, let data) {
    // Handle other HTTP errors
} catch NetworkError.noConnection {
    // Handle offline
} catch {
    // Handle other errors
}
```

## Architecture

```
NetworkKit/
├── Core/           # HTTPMethod, HTTPHeader, Endpoint, NetworkError
├── Request/        # RequestBuilder, MultipartFormData
├── Interceptor/    # Request & Response interceptor protocols
├── Retry/          # RetryPolicy with exponential backoff
├── Client/         # NetworkClient protocol + URLSessionClient
└── Extensions/     # URLRequest & Data helpers
```

## Tech Stack

- Swift 5.9+
- URLSession
- Swift Concurrency (async/await)
- Swift Package Manager

## License

MIT License. See [LICENSE](LICENSE) for details.
