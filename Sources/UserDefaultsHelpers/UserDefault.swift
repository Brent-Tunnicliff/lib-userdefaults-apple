// Copyright © 2025 Brent Tunnicliff <brent@tunnicliff.dev>

import Combine
import Foundation
import Observation
public import SwiftUI

/// Property wrapper that observes the value of `UserDefaults`.
///
/// Expects value to conform to `Equatable` to reduce excessive State updates.
/// While `@AppStorage` does the same, it uses strings to manage the value, whereas this one uses
/// key path instead to make it compile time checked, and also takes advantage of the publisher support of UserDefaults.
@propertyWrapper
public struct UserDefault<Value: Equatable>: DynamicProperty {
    @State private var inner: Inner

    /// A binding to the value.
    @MainActor
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    /// The wrapped object.
    @MainActor
    public var wrappedValue: Value {
        get { inner.value }
        nonmutating set {
            inner.update(newValue)
        }
    }

    /// Initialises wrapper of a single property of `UserDefaults`.
    /// - Parameters:
    ///   - key: Key path reference to the value to be wrapped.
    ///   - store: The instance of `UserDefaults` to observe. Defaults to `.standard`,
    public init(_ key: ReferenceWritableKeyPath<UserDefaults, Value>, store: UserDefaults = .standard) {
        self._inner = State(wrappedValue: Inner(key: key, store: store))
    }
}

extension UserDefault {
    @Observable
    final class Inner {
        private(set) var value: Value

        @ObservationIgnored
        private var cancellables: Set<AnyCancellable> = []
        private let key: ReferenceWritableKeyPath<UserDefaults, Value>
        private let store: UserDefaults

        init(key: ReferenceWritableKeyPath<UserDefaults, Value>, store: UserDefaults) {
            self.key = key
            self.store = store
            self.value = store[keyPath: key]

            store.publisher(for: key)
                .sink { [weak self] in
                    guard let self, value != $0 else {
                        return
                    }

                    value = $0
                }
                .store(in: &cancellables)
        }

        func update(_ value: Value) {
            store[keyPath: key] = value
        }
    }
}
