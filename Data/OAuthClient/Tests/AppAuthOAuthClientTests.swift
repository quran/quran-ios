//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import Foundation
import XCTest
@testable import OAuthClient

final class AppAuthOAuthClientTests: XCTestCase {

    var sut: AppAuthOAuthClient!

    func testLoginWithoutConfigurations() async throws {
        sut = AppAuthOAuthClient()
        do {
            try await sut.login(on: UIViewController())
            XCTFail("Expected to throw error")
        }
        catch {
            // TODO
        }
    }
}
