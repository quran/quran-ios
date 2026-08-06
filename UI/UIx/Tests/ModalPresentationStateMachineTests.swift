//
//  ModalPresentationStateMachineTests.swift
//
//

import XCTest
@testable import UIx

final class ModalPresentationStateMachineTests: XCTestCase {
    func test_dismissalDuringPresentation_waitsForPresentationToFinish() {
        var sut = ModalPresentationStateMachine<Int>()

        XCTAssertEqual(sut.requestPresentation(1), .present(1))
        XCTAssertNil(sut.requestDismissal())
        XCTAssertEqual(sut.didPresent(), .dismiss)
        XCTAssertNil(sut.didDismiss())
        XCTAssertEqual(sut.phase, .idle)
    }

    func test_newPresentationDuringPresentation_replacesAfterCurrentDismisses() {
        var sut = ModalPresentationStateMachine<Int>()

        XCTAssertEqual(sut.requestPresentation(1), .present(1))
        XCTAssertNil(sut.requestPresentation(2))
        XCTAssertEqual(sut.didPresent(), .dismiss)
        XCTAssertEqual(sut.didDismiss(), .present(2))
        XCTAssertEqual(sut.phase, .presenting)
    }

    func test_newPresentationWhilePresented_dismissesBeforePresentingReplacement() {
        var sut = ModalPresentationStateMachine<Int>()

        XCTAssertEqual(sut.requestPresentation(1), .present(1))
        XCTAssertNil(sut.didPresent())
        XCTAssertEqual(sut.requestPresentation(2), .dismiss)
        XCTAssertEqual(sut.didDismiss(), .present(2))
    }

    func test_dismissalWhileDismissing_cancelsPendingPresentation() {
        var sut = ModalPresentationStateMachine<Int>()

        XCTAssertEqual(sut.requestPresentation(1), .present(1))
        XCTAssertNil(sut.didPresent())
        XCTAssertEqual(sut.requestPresentation(2), .dismiss)
        XCTAssertNil(sut.requestDismissal())
        XCTAssertNil(sut.didDismiss())
        XCTAssertEqual(sut.phase, .idle)
    }
}
