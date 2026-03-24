// NetworkKit — Async/Await Networking Library for Swift
//
// Public API Reference
// ====================
//
// Core Types:
//   - HTTPMethod          → GET, POST, PUT, DELETE, PATCH
//   - HTTPHeader          → Name-value header pairs with static factories
//   - Endpoint            → Protocol defining an API endpoint
//   - NetworkError        → Typed error cases for all failure scenarios
//
// Request Building:
//   - RequestBuilder      → Converts Endpoint → URLRequest
//   - MultipartFormData   → Builds multipart/form-data bodies for file uploads
//
// Interceptors:
//   - RequestInterceptor  → Modify requests before sending (auth, headers)
//   - ResponseInterceptor → Process responses before returning (logging)
//
// Retry:
//   - RetryPolicy         → Configurable retry with exponential backoff
//
// Client:
//   - NetworkClient       → Protocol for sending requests
//   - URLSessionClient    → Concrete URLSession-based implementation
//
// Quick Start:
//
//   let client = URLSessionClient()
//   let users: [User] = try await client.send(MyEndpoint())
//
