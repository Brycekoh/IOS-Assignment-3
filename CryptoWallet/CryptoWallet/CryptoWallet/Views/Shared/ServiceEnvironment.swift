//
//  ServiceEnvironment.swift
//  CryptoWallet
//
//  Makes the CryptoServiceProtocol available through the SwiftUI
//  environment so any view can grab it when it needs to spin up its
//  own ViewModel (e.g. CoinDetailViewModel is created on-demand inside
//  the navigation destination).
//
//  This is the standard SwiftUI pattern for dependency injection in
//  iOS 17+: define an EnvironmentKey, expose it through a property on
//  EnvironmentValues, set it once at the app root with `.environment(\.cryptoService, …)`.
//
//  Going through the environment (not a singleton) means tests and
//  previews can inject MockCryptoService at any view in the hierarchy
//  without touching production code — directly serves "loose coupling".
//

import SwiftUI

private struct CryptoServiceKey: EnvironmentKey {
    // The default keeps previews working even when nobody has explicitly
    // injected a service — they get the mock for free.
    static let defaultValue: any CryptoServiceProtocol = MockCryptoService()
}

extension EnvironmentValues {
    var cryptoService: any CryptoServiceProtocol {
        get { self[CryptoServiceKey.self] }
        set { self[CryptoServiceKey.self] = newValue }
    }
}
