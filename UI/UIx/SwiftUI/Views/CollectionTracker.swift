//
//  CollectionTracker.swift
//
//
//  Created by Mohamed Afifi on 2024-01-27.
//

import SwiftUI

// MARK: - TrackingView

private class TrackingTargetView<Item: Hashable>: UIView {
    var item: Item

    init(item: Item) {
        self.item = item
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct TrackingTargetViewRepresentable<Item: Hashable>: UIViewRepresentable {
    let item: Item

    func makeUIView(context: Context) -> TrackingTargetView<Item> {
        TrackingTargetView(item: item)
    }

    func updateUIView(_ view: TrackingTargetView<Item>, context: Context) {
        view.item = item
    }
}

private struct TrackingTargetModifier<Item: Hashable>: ViewModifier {
    let item: Item

    func body(content: Content) -> some View {
        content
            .background(TrackingTargetViewRepresentable(item: item))
    }
}

// MARK: - TrackingContainer

private class CollectionTrackerView: UIView {}

private struct CollectionTrackerViewRepresentable<Item: Hashable>: UIViewRepresentable {
    let tracker: CollectionTracker<Item>

    func makeUIView(context: Context) -> CollectionTrackerView {
        let view = CollectionTrackerView()
        updateUIView(view, context: context)
        return view
    }

    func updateUIView(_ view: CollectionTrackerView, context: Context) {
        tracker.view = view
    }
}

public final class CollectionTracker<Item: Hashable> {
    fileprivate weak var view: CollectionTrackerView?

    public init() {}

    private var visibleViews: [TrackingTargetView<Item>] {
        for viewToTry in [view, view?.superview, view?.superview?.superview] {
            if let visibleViews = viewToTry?.findVisibleSubviews(ofType: TrackingTargetView<Item>.self), !visibleViews.isEmpty {
                return visibleViews
            }
        }
        return []
    }

    public func itemAtPoint(_ point: CGPoint, from: UICoordinateSpace) -> Item? {
        for visibleView in visibleViews {
            let localPoint = visibleView.convert(point, from: from)
            if visibleView.point(inside: localPoint, with: nil) {
                return visibleView.item
            }
        }
        return nil
    }
}

private struct CollectionTrackerModifier<Item: Hashable>: ViewModifier {
    let tracker: CollectionTracker<Item>

    func body(content: Content) -> some View {
        content
            .background(CollectionTrackerViewRepresentable(tracker: tracker))
    }
}

extension View {
    public func trackingTarget(item: some Hashable) -> some View {
        modifier(TrackingTargetModifier(item: item))
    }

    public func trackCollection(with tracker: CollectionTracker<some Hashable>) -> some View {
        modifier(CollectionTrackerModifier(tracker: tracker))
    }
}
