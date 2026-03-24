# How Does NetworkKit Work?

## What Is This Library For?

When building a mobile app, you almost always need to fetch data from the internet. For example:
- Loading a news feed from a server
- Listing products in an e-commerce app
- Handling user login
- Uploading a profile picture

Instead of writing this logic from scratch every time, **NetworkKit** gives you a ready-made infrastructure. You just say "fetch this data from this address" and it handles the rest.

---

## Real-World Analogy

Think of NetworkKit as a **delivery service**:

| Delivery Service | NetworkKit |
|------------------|------------|
| Delivery address | `Endpoint` (API address) |
| Filling out the shipping form | `RequestBuilder` (preparing the request) |
| Attaching labels before shipping | `RequestInterceptor` (adding auth tokens, etc.) |
| Redelivery if it fails | `RetryPolicy` (automatic retry) |
| Delivery notification | `ResponseInterceptor` (processing the response) |
| The delivery company itself | `URLSessionClient` (the thing doing the work) |

---

## Core Building Blocks

### 1. Endpoint — "Where am I sending this request?"

To make an API call, you need to know:
- **Base URL**: `https://api.example.com`
- **Path**: `/users`
- **Method**: Are you fetching data (GET)? Sending data (POST)?
- **Headers**: Authentication info, content type, etc.
- **Body**: Data to send (e.g., new user info)

In NetworkKit, you define these as an `Endpoint`:

```swift
// "Get all users" endpoint
struct GetUsersEndpoint: Endpoint {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var method: HTTPMethod { .get }
}
```

That's it. You can now use this endpoint to make a request.

### 2. HTTPMethod — "What kind of request?"

There are 5 basic HTTP request types:

| Method | When to Use | Example |
|--------|-------------|---------|
| **GET** | Fetch data | Get the product list |
| **POST** | Create new data | Register a new user |
| **PUT** | Replace existing data entirely | Update full profile |
| **PATCH** | Update part of existing data | Change only the name |
| **DELETE** | Remove data | Delete an account |

### 3. HTTPHeader — "Attach extra info to the request"

Headers are metadata attached to a request. Most common uses:

```swift
// "I'm sending JSON"
.contentType("application/json")

// "I want JSON back"
.accept("application/json")

// "Here's my identity" (for logged-in users)
.bearerToken("abc123xyz")
```

### 4. NetworkError — "Something went wrong"

Internet requests don't always succeed. NetworkKit categorizes errors into meaningful types:

| Error | Meaning |
|-------|---------|
| `invalidURL` | The URL is malformed |
| `unauthorized` | Session expired or not logged in (401) |
| `requestFailed(statusCode, data)` | Server returned an error (404, 500, etc.) |
| `decodingFailed` | Response doesn't match the expected format |
| `timeout` | The request took too long |
| `noConnection` | No internet connection |
| `noData` | Server returned an empty response |

This lets you handle each error differently:

```swift
do {
    let users: [User] = try await client.send(endpoint)
} catch NetworkError.unauthorized {
    // Redirect to login screen
} catch NetworkError.noConnection {
    // Show "Check your internet connection"
} catch NetworkError.timeout {
    // Show "Server not responding, try again"
}
```

### 5. RequestBuilder — "Convert the Endpoint into a real request"

You define an `Endpoint`, but the operating system understands `URLRequest`. The `RequestBuilder` handles the translation:

```
Your Endpoint  →  RequestBuilder  →  URLRequest (system understands this)
```

Behind the scenes, it:
- Combines base URL + path (`https://api.example.com` + `/users`)
- Appends query parameters (`?page=1&limit=20`)
- Sets headers
- Encodes the body as JSON

### 6. Interceptors — "Catch the request on its way and modify it"

Interceptors act like **security checkpoints**. They step in before the request goes out, or after the response comes back.

**Request Interceptor** — Before the request leaves:
```swift
// Automatically add the user token to every request
struct AuthInterceptor: RequestInterceptor {
    let token: String

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
```

This way you don't have to manually add the token to every endpoint. The interceptor does it automatically for every request.

**Response Interceptor** — After the response arrives:
```swift
// Log every response (useful for debugging)
struct LoggingInterceptor: ResponseInterceptor {
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        print("Status: \(response.statusCode)")
        print("Data: \(String(data: data, encoding: .utf8) ?? "")")
        return data
    }
}
```

### 7. RetryPolicy — "If it fails, try again"

Sometimes a server temporarily can't respond (overload, maintenance, etc.). In those cases, it makes sense to automatically retry the request.

```swift
RetryPolicy(
    maxRetryCount: 3,          // Try up to 3 times
    delay: .seconds(1),        // Wait 1 second before the first retry
    backoffMultiplier: 2.0,    // Double the wait time after each retry
    retryableStatusCodes: [500, 502, 503]  // Only retry for these errors
)
```

**How Exponential Backoff works:**
```
1st attempt fails → wait 1 second  → retry
2nd attempt fails → wait 2 seconds → retry
3rd attempt fails → wait 4 seconds → retry
Still failing     → throw error
```

The wait time increases because if the server is already overloaded, bombarding it with rapid requests only makes things worse.

### 8. URLSessionClient — "The Engine That Brings Everything Together"

This class combines all the pieces. Here's the request flow:

```
1. Take the Endpoint
2. Convert to URLRequest via RequestBuilder
3. Run through Request Interceptors (add token, etc.)
4. Send via URLSession
5. If error and retry policy allows → retry
6. If success, run through Response Interceptors
7. Decode JSON and return the result
```

```swift
// Configure the client
let client = URLSessionClient(
    retryPolicy: RetryPolicy(maxRetryCount: 3, delay: .seconds(1)),
    requestInterceptors: [AuthInterceptor(token: "abc123")]
)

// Make a request — one line
let users: [User] = try await client.send(GetUsersEndpoint())
```

### 9. MultipartFormData — "Upload Files"

Uploading photos or files requires a special format: `multipart/form-data`. This structure lets you send both text and file data in a single request.

```swift
var form = MultipartFormData()
form.addField(name: "caption", value: "My profile photo")
form.addFile(
    name: "photo",
    data: imageData,
    fileName: "profile.jpg",
    mimeType: "image/jpeg"
)

let body = form.encode() // Ready-to-send Data
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│                   YOU (Developer)                    │
│                                                     │
│   let users: [User] = try await client.send(ep)     │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                  RequestBuilder                      │
│           Endpoint → URLRequest conversion           │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│              Request Interceptors                    │
│        Add tokens, modify headers, etc.             │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                  URLSession                          │
│           Send the request over the network          │
└─────────────────────┬───────────────────────────────┘
                      │
              ┌───────┴───────┐
              ▼               ▼
           Success          Failure
              │               │
              │         Check Retry
              │           Policy
              │               │
              │        ┌──────┴──────┐
              │        ▼             ▼
              │    Retry         Throw error
              │
              ▼
┌─────────────────────────────────────────────────────┐
│             Response Interceptors                    │
│          Logging, data transformation, etc.          │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                  JSON Decode                         │
│            Data → Swift model conversion             │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
                 [User] 🎉
```

---

## Why Was It Designed This Way?

| Design Decision | Reason |
|-----------------|--------|
| **Protocol-based (Endpoint, NetworkClient)** | You can swap in mock implementations for testing |
| **Interceptor pattern** | Common tasks like auth are managed in one place |
| **Retry policy** | Transient failures don't ruin the user experience |
| **Sendable compliant** | Works safely with Swift's modern concurrency system |
| **SPM package** | Can be added to any project with a single line |

---

## Quick Start Summary

```swift
// 1. Define an endpoint
struct GetPosts: Endpoint {
    var baseURL: URL { URL(string: "https://jsonplaceholder.typicode.com")! }
    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

// 2. Define a model
struct Post: Decodable, Sendable {
    let id: Int
    let title: String
    let body: String
}

// 3. Create a client and use it
let client = URLSessionClient()
let posts: [Post] = try await client.send(GetPosts())
print(posts.first?.title ?? "")
```

That's it. Three steps to fetch data from the internet.
