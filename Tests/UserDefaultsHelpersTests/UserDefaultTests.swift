// Copyright © 2025 Brent Tunnicliff <brent@tunnicliff.dev>

import Foundation
import Testing
import UserDefaultsHelpers

// MARK: - Setup

@MainActor
struct UserDefaultTests {
    private let userDefaults = UserDefaults.forTest()
    @UserDefault private var valueForTesting: String?

    init() {
        self._valueForTesting = UserDefault(\.valueForTesting, store: userDefaults)
    }
}

// MARK: - Tests

extension UserDefaultTests {
    @Test
    func settingValueIsStoredInUserDefaults() {
        let newValue = #function
        valueForTesting = newValue
        #expect(userDefaults.valueForTesting == newValue)
    }

    @Test
    func gettingValueReturnsUserDefaultsValue() {
        let newValue = #function
        userDefaults.valueForTesting = newValue
        #expect(valueForTesting == newValue)
    }

    // Adding a time limit as a backup. One minute is currently the minimum.
    @Test(.timeLimit(.minutes(1)))
    func observingValueGetsTriggeredOnNewValue() async throws {
        try await performObservationTest {
            valueForTesting = #function
        }
    }

    // Adding a time limit as a backup. One minute is currently the minimum.
    @Test(.timeLimit(.minutes(1)))
    func observingValueGetsTriggeredOnUserDefaultValueChange() async throws {
        try await performObservationTest {
            userDefaults.valueForTesting = #function
        }
    }
}

// MARK: - Helpers

extension UserDefaultTests {
    fileprivate func performObservationTest(_ updateAction: () -> Void) async throws {
        var iterator = AsyncThrowingStream { continuation in
            withObservationTracking {
                _ = valueForTesting
            } onChange: {
                continuation.yield()
                continuation.finish()
            }

            Task {
                try await Task.sleep(for: .seconds(1))
                continuation.finish(throwing: TestError.testTimedOut)
            }

            updateAction()
        }.makeAsyncIterator()

        // As long as this completes and does not throw,
        // then it is considered a pass.
        _ = try await iterator.next()
    }
}

extension UserDefaults {
    @objc fileprivate dynamic var valueForTesting: String? {
        get {
            string(forKey: #function)
        }
        set {
            setValue(newValue, forKey: #function)
        }
    }
}
