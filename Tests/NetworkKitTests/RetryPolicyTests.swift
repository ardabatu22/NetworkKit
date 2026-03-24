import XCTest
@testable import NetworkKit

final class RetryPolicyTests: XCTestCase {

    func testDefaultPolicy() {
        let policy = RetryPolicy.default
        XCTAssertEqual(policy.maxRetryCount, 3)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
    }

    func testNonePolicy() {
        let policy = RetryPolicy.none
        XCTAssertEqual(policy.maxRetryCount, 0)
    }

    func testShouldRetryForRetryableStatusCode() {
        let policy = RetryPolicy.default
        XCTAssertTrue(policy.shouldRetry(statusCode: 500))
        XCTAssertTrue(policy.shouldRetry(statusCode: 502))
        XCTAssertTrue(policy.shouldRetry(statusCode: 503))
        XCTAssertTrue(policy.shouldRetry(statusCode: 429))
    }

    func testShouldNotRetryForNonRetryableStatusCode() {
        let policy = RetryPolicy.default
        XCTAssertFalse(policy.shouldRetry(statusCode: 200))
        XCTAssertFalse(policy.shouldRetry(statusCode: 400))
        XCTAssertFalse(policy.shouldRetry(statusCode: 401))
        XCTAssertFalse(policy.shouldRetry(statusCode: 404))
    }

    func testExponentialBackoffDelay() {
        let policy = RetryPolicy(delay: .seconds(1), backoffMultiplier: 2.0)

        let delay0 = policy.delay(for: 0)
        let delay1 = policy.delay(for: 1)
        let delay2 = policy.delay(for: 2)

        XCTAssertEqual(delay0, .nanoseconds(1_000_000_000))  // 1s
        XCTAssertEqual(delay1, .nanoseconds(2_000_000_000))  // 2s
        XCTAssertEqual(delay2, .nanoseconds(4_000_000_000))  // 4s
    }

    func testCustomRetryableStatusCodes() {
        let policy = RetryPolicy(retryableStatusCodes: [418])
        XCTAssertTrue(policy.shouldRetry(statusCode: 418))
        XCTAssertFalse(policy.shouldRetry(statusCode: 500))
    }
}
