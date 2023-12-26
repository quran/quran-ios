//
//  DisableSafeAreaInsets.swift
//
//
//  Created by Mohamed Afifi on 2023-12-25.
//

import SwiftUI

// From:https://github.com/SwiftUIX/SwiftUIX/blob/2bf8eda3acad39b0419e4053d321059030cfa04b/Sources/SwiftUIX/Intramodular/Bridging/CocoaHostingController.swift#L263C17-L263C39

extension UIHostingController {
    /// https://twitter.com/b3ll/status/1193747288302075906
    public func _disableSafeAreaInsets() {
        guard let viewClass = object_getClass(view), !String(cString: class_getName(viewClass)).hasSuffix("_SwiftUIX_patched") else {
            return
        }

        let className = String(cString: class_getName(viewClass)).appending("_SwiftUIX_patched")

        if let viewSubclass = NSClassFromString(className) {
            object_setClass(view, viewSubclass)
        } else {
            className.withCString { className in
                guard let subclass = objc_allocateClassPair(viewClass, className, 0) else {
                    return
                }

                if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                    let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                        .zero
                    }

                    class_addMethod(subclass, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
                }

                if let method2 = class_getInstanceMethod(viewClass, #selector(getter: UIView.safeAreaLayoutGuide)) {
                    let safeAreaLayoutGuide: @convention(block) (AnyObject) -> UILayoutGuide? = { (_: AnyObject!) -> UILayoutGuide? in
                        nil
                    }

                    class_replaceMethod(viewClass, #selector(getter: UIView.safeAreaLayoutGuide), imp_implementationWithBlock(safeAreaLayoutGuide), method_getTypeEncoding(method2))
                }

                objc_registerClassPair(subclass)
                object_setClass(view, subclass)
            }

            view.setNeedsDisplay()
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
}
