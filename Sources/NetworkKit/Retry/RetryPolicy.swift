import Foundation

/// Configurable retry policy with exponential backoff.
public struct RetryPolicy: Sendable {

    // MARK: - Properties

    /// Maximum number of retry attempts.
    public let maxRetryCount: Int

    /// Base delay between retries.
    public let delay: Duration

    /// Multiplier applied to the delay after each retry.
    public let backoffMultiplier: Double

    /// HTTP status codes that should trigger a retry.
    public let retryableStatusCodes: Set<Int>

    // MARK: - Init

    public init(
        maxRetryCount: Int = 3,
        delay: Duration = .seconds(1),
        backoffMultiplier: Double = 2.0,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxRetryCount = maxRetryCount
        self.delay = delay
        self.backoffMultiplier = backoffMultiplier
        self.retryableStatusCodes = retryableStatusCodes
    }

    // MARK: - Public Methods

    /// Returns the delay for a given attempt number (0-indexed).
    public func delay(for attempt: Int) -> Duration {
        let multiplier = pow(backoffMultiplier, Double(attempt))
        let nanoseconds = Double(delay.components.seconds) * 1_000_000_000
            + Double(delay.components.attoseconds) / 1_000_000_000
        let delayNanoseconds = nanoseconds * multiplier
        return .nanoseconds(Int64(delayNanoseconds))
    }

    /// Returns whether the given status code should be retried.
    public func shouldRetry(statusCode: Int) -> Bool {
        retryableStatusCodes.contains(statusCode)
    }

    // MARK: - Presets

    /// Default retry policy: 3 retries, 1 second base delay, 2x backoff.
    public static let `default` = RetryPolicy()

    /// No retries.
    public static let none = RetryPolicy(maxRetryCount: 0)
}
