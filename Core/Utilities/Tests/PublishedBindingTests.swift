import Combine
import Utilities
import XCTest

@MainActor
final class PublishedBindingTests: XCTestCase {
    func testInitialValueDoesNotPublishAChange() {
        let source = Source(value: 1)
        let sut = Model(source: source)
        var changes = 0
        let cancellable = sut.objectWillChange.sink { changes += 1 }

        XCTAssertEqual(sut.value, 1)
        XCTAssertEqual(changes, 0)
        withExtendedLifetime(cancellable) {}
    }

    func testSourceUpdatePublishesChangedValue() {
        let source = Source(value: 1)
        let sut = Model(source: source)
        var changes = 0
        let cancellable = sut.objectWillChange.sink { changes += 1 }
        _ = sut.value

        source.value = 2

        XCTAssertEqual(sut.value, 2)
        XCTAssertEqual(changes, 1)
        withExtendedLifetime(cancellable) {}
    }

    func testEqualSourceUpdateDoesNotPublishAChange() {
        let source = Source(value: 1)
        let sut = Model(source: source)
        var changes = 0
        let cancellable = sut.objectWillChange.sink { changes += 1 }
        _ = sut.value

        source.value = 1

        XCTAssertEqual(sut.value, 1)
        XCTAssertEqual(changes, 0)
        withExtendedLifetime(cancellable) {}
    }

    func testSettingValueWritesToSourceAndPublishesSourceUpdateOnce() {
        let source = Source(value: 1)
        let sut = Model(source: source)
        var changes = 0
        let cancellable = sut.objectWillChange.sink { changes += 1 }
        _ = sut.value

        sut.value = 2

        XCTAssertEqual(source.value, 2)
        XCTAssertEqual(sut.value, 2)
        XCTAssertEqual(changes, 1)
        withExtendedLifetime(cancellable) {}
    }

    func testSettingEqualValueDoesNotWriteToSource() {
        let source = Source(value: 1)
        let sut = Model(source: source)
        _ = sut.value

        sut.value = 1

        XCTAssertEqual(source.numberOfWrites, 0)
    }

    func testProjectionWaitsForSourceUpdate() {
        let updates = PassthroughSubject<Int, Never>()
        var writtenValues: [Int] = []
        let sut = Model(
            initialValue: 1,
            updates: updates.eraseToAnyPublisher(),
            set: { writtenValues.append($0) }
        )
        _ = sut.value

        sut.value = 2

        XCTAssertEqual(writtenValues, [2])
        XCTAssertEqual(sut.value, 1)

        updates.send(3)

        XCTAssertEqual(sut.value, 3)
    }

    func testProjectedPublisherEmitsInitialAndChangedSourceValues() {
        let source = Source(value: 1)
        let sut = Model(source: source)
        var values: [Int] = []
        let cancellable = sut.$value.sink { values.append($0) }

        source.value = 1
        source.value = 2

        XCTAssertEqual(values, [1, 2])
        withExtendedLifetime(cancellable) {}
    }
}

@MainActor
private final class Model: ObservableObject {
    @PublishedBinding var value: Int

    init(source: Source) {
        _value = PublishedBinding(
            wrappedValue: source.value,
            updates: source.updates,
            set: { source.value = $0 }
        )
    }

    init(initialValue: Int, updates: AnyPublisher<Int, Never>, set: @escaping (Int) -> Void) {
        _value = PublishedBinding(
            wrappedValue: initialValue,
            updates: updates,
            set: set
        )
    }
}

@MainActor
private final class Source {
    var value: Int {
        didSet {
            numberOfWrites += 1
            subject.send(value)
        }
    }

    var updates: AnyPublisher<Int, Never> {
        subject.eraseToAnyPublisher()
    }

    private(set) var numberOfWrites = 0

    private let subject = PassthroughSubject<Int, Never>()

    init(value: Int) {
        self.value = value
    }
}
