// Copyright © 2025 Brent Tunnicliff <brent@tunnicliff.dev>

import Foundation

extension UserDefaults {
    /// Creates a new instance of UserDefaults for the test.
    ///
    /// Uses UUID as part of the suite name to reduce chance of tests using the same state.
    /// Takes in the file, function and line for use in the suite name for debugging purposes.
    static func forTest(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> UserDefaults {
        let suiteName = "\(file):\(function):\(line):\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: UUID().uuidString) else {
            preconditionFailure("Unable to create UserDefaults for testing: \(suiteName)")
        }

        // The chance of reuse is tiny, but just incase lets wipe it before returning.
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key)
        }

        return userDefaults
    }
}
