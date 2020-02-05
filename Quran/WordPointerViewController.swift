//
//  WordPointerViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Popover_OC
import RIBs
import RxSwift
import UIKit

protocol WordPointerPresentableListener: class {
    func onViewPanBegan()
    func onViewPanChanged(to point: CGPoint, in view: UIView)
    func onViewPanEnded()
    func onViewTapped()
    func didDismissPopover()
}

final class WordPointerViewController: UIViewController, WordPointerPresentable, WordPointerViewControllable, PopoverPresenterDelegate {

    weak var listener: WordPointerPresentableListener?

    // For translations selection
    private lazy var popoverPresenter = PhonePopoverPresenter(delegate: self)

    // For word translation
    private lazy var popover: PopoverView = PopoverView(view: container)

    // swiftlint:disable implicitly_unwrapped_optional
    private var container: UIView!
    private var pointerTop: NSLayoutConstraint!
    private var pointerLeft: NSLayoutConstraint!
    // swiftlint:enable implicitly_unwrapped_optional

    private var pointerParentSize: CGSize = .zero

    private func setPointerTop(_ value: CGFloat) {
        pointerTop.constant = value
        pointerParentSize = container.bounds.size
    }
    private func setPointerLeft(_ value: CGFloat) {
        pointerLeft.constant = value
    }

    private var minX: CGFloat {
        return Layout.windowDirectionalSafeAreaInsets.leading
    }
    private var maxX: CGFloat {
        return container.bounds.width - Layout.windowDirectionalSafeAreaInsets.trailing
    }

    override func loadView() {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "pointer-25").withRenderingMode(.alwaysTemplate)

        imageView.layer.shadowColor = Theme.Kind.labelWeak.color.cgColor
        imageView.layer.shadowOpacity = 0.6
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOffset = CGSize(width: 1, height: 1)

        let pointer = UIView()
        pointer.isHidden = true
        pointer.vc.size(by: 44)

        pointer.addAutoLayoutSubview(imageView)
        imageView.vc.center()

        view = pointer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanned(_:)))
        view.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func onTapped() {
        listener?.onViewTapped()
    }

    // MARK: - Layout

    private func initializeContainer() {
        guard container == nil else {
            return
        }
        container = view.superview
        for constraint in container.constraints {
            if constraint.firstItem === view && constraint.secondItem === container {
                if constraint.relation == .equal {
                    let isAttribute = { constraint.firstAttribute == $0 && constraint.secondAttribute == $0 }
                    if isAttribute(.top) {
                        pointerTop = constraint
                    } else if isAttribute(.left) {
                        pointerLeft = constraint
                    }
                }
            }
        }
        precondition(pointerTop != nil, "Couldn't find a top constraint for WordPointerViewContrller.view")
        precondition(pointerLeft != nil, "Couldn't find a left constraint for WordPointerViewContrller.view")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard container != nil else {
            return
        }

        if pointerParentSize != container.bounds.size {
            setPointerTop(view.frame.minY * container.bounds.height / pointerParentSize.height)
            // using container.bounds.height because it has been rotated but view.frame.minX has not
            if view.frame.minX > container.bounds.height / 2 {
                setPointerLeft(maxX - view.bounds.width)
            } else {
                setPointerLeft(minX)
            }
        }
    }

    private var startPointerPosition: CGPoint = .zero

    @objc private func onPanned(_ gesture: UIPanGestureRecognizer) {

        switch gesture.state {
        case .began:
            listener?.onViewPanBegan()
            startPointerPosition = CGPoint(x: view.frame.minX, y: view.frame.minY)
        case .changed:
            let translation = gesture.translation(in: container)
            setPointerTop(startPointerPosition.y + translation.y)
            setPointerLeft(startPointerPosition.x + translation.x)
            container.layoutIfNeeded()
            listener?.onViewPanChanged(to: CGPoint(x: view.frame.maxX - 15, y: view.frame.minY + 15), in: container)
        case .ended, .cancelled, .failed:
            listener?.onViewPanEnded()

            let velocity = gesture.velocity(in: container)

            let goLeft: Bool
            if abs(velocity.x) > 100 {
                goLeft = velocity.x < 0
            } else {
                goLeft = view.center.x < container.bounds.width / 2
            }

            let finalY = max(10, min(container.bounds.height - view.bounds.height, velocity.y * 0.3 + view.frame.minY))
            let finalX = goLeft ? minX : maxX - view.bounds.width

            let y = finalY - view.frame.minY
            let x = finalX - view.frame.minX
            let springVelocity = abs(velocity.x) / sqrt(x * x + y * y)

            setPointerTop(finalY)
            setPointerLeft(finalX)
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: springVelocity,
                           options: [],
                           animations: {
                self.container.layoutIfNeeded()
            }, completion: nil)

        case .possible: break
        }
    }

    // MARK: - Animation

    func animateIn() {
        if container == nil {
            initializeContainer()
        }
        view.isHidden = false

        // initial position
        setPointerTop(container.bounds.height)
        setPointerLeft(container.bounds.width / 2)
        container.layoutIfNeeded()

        // final position
        setPointerTop(container.bounds.height / 4)
        setPointerLeft(minX)
        UIView.animate(withDuration: 0.5, delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0,
                       animations: {
                        self.container.layoutIfNeeded()
        }, completion: nil)
    }

    func animateOut(completion: @escaping () -> Void) {
        let finalY = container.bounds.height + 200
        setPointerTop(finalY)
        setPointerLeft(container.bounds.width / 2)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0,
                       animations: {
                        self.container.layoutIfNeeded()
        }, completion: { _ in
            if self.pointerTop?.constant == finalY {
                completion()
            }
        })
    }

    // MARK: - Word Popover

    func showWordPopover(text: String, at point: CGPoint) {
        let isUpward = point.y < 63
        let action = PopoverAction(title: text, handler: nil)
        popover.show(to: point, isUpward: isUpward, with: [action])
    }

    func hideWordPopover() {
        popover.hideNoAnimation()
    }
    
    lazy var castParent = container as? QuranView

    func showWordPopover(text: String, at point: CGPoint, word: AyahWord, position: AyahWord.Position) {
        let page = Quran.pageForAyah(position.ayah)

        guard let cells = castParent?.collectionView.visibleCells as? [QuranImagePageCollectionViewCell],
            let cell = cells.first(where: { $0.page?.pageNumber == page }),
            let infos = cell.highlightingView.ayahInfoData?[position.ayah],
            let info = infos.first(where: { $0.position == position.position }),
            let croppedImage = cell.mainImageView.image?.cgImage?.cropping(to: info.rect) else { return }
        var action: PopoverAction
        var wordImage = UIImage(cgImage: croppedImage)
        if Theme.current == .light {
            wordImage = wordImage.inverted()
        }
        wordImage = wordImage.aspectFittedToHeight(40.0 - 8.0 * 2)
        action = PopoverAction(image: wordImage, title: text, handler: nil)
        let isUpward = point.y < 63
        popover.show(to: point, isUpward: isUpward, with: [action])
    }

    // MARK: - Translation Selection

    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable) {
        popoverPresenter.present(presenting: self,
                                 presented: viewController.uiviewController,
                                 pointingTo: view,
                                 at: view.bounds,
                                 permittedArrowDirections: [.left, .right])
    }

    func didDismissPopover() {
        listener?.didDismissPopover()
    }
}
