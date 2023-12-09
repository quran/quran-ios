//
//  WordPointerViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import NoorUI
import Popover_OC
import UIKit
import UIx
import VLogging

public final class WordPointerViewController: UIViewController {
    private enum GestureState {
        case began
        case changed(translation: CGPoint)
        case ended(velocity: CGPoint)
    }

    // MARK: Lifecycle

    init(viewModel: WordPointerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public func loadView() {
        let imageView = UIImageView()
        imageView.image = NoorImage.pointer.uiImage.withRenderingMode(.alwaysTemplate)

        imageView.layer.shadowColor = UIColor.systemGray.cgColor
        imageView.layer.shadowOpacity = 0.6
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOffset = CGSize(width: 1, height: 1)

        pointer = UIView()

        pointer.addAutoLayoutSubview(imageView)
        imageView.vc.center()

        let view = ByPassTouchesView()
        view.catchTouchesView = pointer
        view.isHidden = true

        view.addAutoLayoutSubview(pointer)
        pointer.vc.size(by: 44)
        pointerTop = pointer.vc.top().constraint
        pointerLeft = pointer.vc.left().constraint

        // magnifying glass
        magnifyingGlass = MagnifyingGlass()
        magnifyingGlass.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        magnifyingGlass.isHidden = true
        view.addSubview(magnifyingGlass)

        self.view = view
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanned(_:)))
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - Actions

    public func hideWordPointer(completion: @escaping () -> Void) {
        animateOut(completion: completion)
    }

    public func showWordPointer(referenceView: UIView) {
        animateIn(referenceView: referenceView)
    }

    // MARK: - Layout

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard pointerParentSize != .zero else {
            return
        }

        if pointerParentSize != container.bounds.size {
            setPointerTop(pointer.frame.minY * container.bounds.height / pointerParentSize.height)
            // using container.bounds.height because it has been rotated but pointer.frame.minX has not
            if pointer.frame.minX > container.bounds.height / 2 {
                setPointerLeft(maxX - pointer.bounds.width)
            } else {
                setPointerLeft(minX)
            }
        }
    }

    // MARK: Internal

    var panningTask: Task<Void, Never>?

    func moveMagnifyingGlass(to point: CGPoint) {
        magnifyingGlass?.touchPoint = point
        magnifyingGlass?.center = CGPoint(x: point.x, y: point.y + (lookingUpward(point) ? 40 : -40))
    }

    // MARK: - Word Popover

    func showWordPopover(text: String, at point: CGPoint) {
        let isUpward = lookingUpward(point)
        let newPoint = CGPoint(x: point.x, y: point.y + (isUpward ? 70 : -70))
        let action = PopoverAction(image: nil, title: text, handler: nil)
        popover.show(to: newPoint, isUpward: isUpward, with: [action])
    }

    func hideWordPopover() {
        popover.hideNoAnimation()
    }

    // MARK: Private

    private let viewModel: WordPointerViewModel

    // For word translation
    private lazy var popover: PopoverView = PopoverView(view: container)

    private var pointerTop: NSLayoutConstraint!
    private var pointerLeft: NSLayoutConstraint!
    private var pointer: UIView!

    private var pointerParentSize: CGSize = .zero

    private var startPointerPosition: CGPoint = .zero

    private var magnifyingGlass: MagnifyingGlass! {
        didSet { oldValue?.removeFromSuperview() }
    }

    private var container: UIView { view }

    private var borderInsets: DirectionalEdgeInsets {
        // TODO: Use the containing window
        UIApplication.shared.windows.first?.directionalSafeAreaInsets ?? .zero
    }

    private var minX: CGFloat {
        borderInsets.leading
    }

    private var maxX: CGFloat {
        container.bounds.width - borderInsets.trailing
    }

    private func setPointerTop(_ value: CGFloat) {
        pointerTop.constant = value
        pointerParentSize = container.bounds.size
    }

    private func setPointerLeft(_ value: CGFloat) {
        pointerLeft.constant = value
    }

    @objc
    private func onPanned(_ gesture: UIPanGestureRecognizer) {
        guard let state = makeGestureState(gesture) else {
            return
        }
        panningTask?.cancel()
        panningTask = Task {
            await asyncOnPanned(state: state)
        }
    }

    private func makeGestureState(_ gesture: UIPanGestureRecognizer) -> GestureState? {
        switch gesture.state {
        case .began:
            logger.debug("Started pointer dragging")
            return .began
        case .changed:
            let translation = gesture.translation(in: container)
            logger.debug("Pointer dragged to new position \(translation)")
            return .changed(translation: translation)
        case .ended, .cancelled, .failed:
            logger.debug("Ended pointer dragging \(gesture.state.rawValue)")
            let velocity = gesture.velocity(in: container)
            return .ended(velocity: velocity)
        case .possible:
            return nil
        @unknown default:
            fatalError("Unimplemented case")
        }
    }

    private func asyncOnPanned(state: GestureState) async {
        switch state {
        case .began:
            viewModel.viewPanBegan()
            startPointerPosition = CGPoint(x: pointer.frame.minX, y: pointer.frame.minY)

        case .changed(let translation):
            setPointerTop(startPointerPosition.y + translation.y)
            setPointerLeft(startPointerPosition.x + translation.x)
            container.layoutIfNeeded()

            let arrowPoint = CGPoint(x: pointer.frame.maxX - 15, y: pointer.frame.minY + 15)

            showMagnifyingGlassIfNeeded()
            moveMagnifyingGlass(to: arrowPoint)
            let status = await viewModel.viewPanned(to: arrowPoint, in: container)
            switch status {
            case .none:
                break
            case .hidePopover:
                hideWordPopover()
            case .showPopover(let text):
                showWordPopover(text: text, at: arrowPoint)
            }

        case .ended(let velocity):
            hideMangifyingGlass()
            hideWordPopover()
            viewModel.unhighlightWord()

            let goLeft: Bool
            if abs(velocity.x) > 100 {
                goLeft = velocity.x < 0
            } else {
                goLeft = pointer.center.x < container.bounds.width / 2
            }

            let finalY = max(10, min(container.bounds.height - pointer.bounds.height, velocity.y * 0.3 + pointer.frame.minY))
            let finalX = goLeft ? minX : maxX - pointer.bounds.width

            let y = finalY - pointer.frame.minY
            let x = finalX - pointer.frame.minX
            let springVelocity = abs(velocity.x) / sqrt(x * x + y * y)

            setPointerTop(finalY)
            setPointerLeft(finalX)
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: springVelocity,
                options: [],
                animations: {
                    self.container.layoutIfNeeded()
                },
                completion: nil
            )
        }
    }

    // MARK: - Animation

    private func animateIn(referenceView: UIView) {
        magnifyingGlass.viewToMagnify = referenceView
        view.isHidden = false

        // initial position
        container.layoutIfNeeded()
        setPointerTop(container.bounds.height)
        setPointerLeft(container.bounds.width / 2)
        container.layoutIfNeeded()

        // final position
        setPointerTop(container.bounds.height / 4)
        setPointerLeft(minX)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            animations: {
                self.container.layoutIfNeeded()
            },
            completion: nil
        )
    }

    private func animateOut(completion: @escaping () -> Void) {
        let finalY = container.bounds.height + 200
        setPointerTop(finalY)
        setPointerLeft(container.bounds.width / 2)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            animations: {
                self.container.layoutIfNeeded()
            },
            completion: { _ in
                if self.pointerTop?.constant == finalY {
                    completion()
                }
            }
        )
    }

    // MARK: - Magnifying Glass

    private func showMagnifyingGlassIfNeeded() {
        if magnifyingGlass.isHidden {
            magnifyingGlass.isHidden = false
            pointer.isHidden = true
        }
    }

    private func hideMangifyingGlass() {
        magnifyingGlass.isHidden = true
        pointer.isHidden = false
    }

    private func lookingUpward(_ point: CGPoint) -> Bool {
        point.y < 130
    }
}
