//
//  Copyright (c) 2017. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
import RIBs
import UIKit

/// Basic interface between a `NavigationRouter` and the UIKit `UINavigationController`.
public protocol NavigationControllable: ViewControllable {
    var uinavigationController: UINavigationController { get }
}

/// Default implementation on `UINavigationController` to conform to `NavigationControllable` protocol
public extension NavigationControllable where Self: UINavigationController {
    var uinavigationController: UINavigationController {
        return self
    }
}

public extension NavigationControllable {
    var uiviewController: UIViewController {
        return uinavigationController
    }
}

public extension NavigationControllable {

    func setViewControllers(_ viewControllers: [ViewControllable], animated: Bool) {
        uinavigationController.setViewControllers(viewControllers.map { $0.uiviewController }, animated: animated)
    }

    func push(_ viewController: ViewControllable, animated: Bool) {
        uinavigationController.pushViewController(viewController.uiviewController, animated: animated)
    }

    func pop(animated: Bool) -> Bool {
        return uinavigationController.popViewController(animated: animated) != nil
    }

    func pop(to viewController: ViewControllable, animated: Bool) -> Bool {
        return uinavigationController.popToViewController(viewController.uiviewController, animated: animated) != nil
    }

    func popToRoot(animated: Bool) -> Bool {
        return uinavigationController.popToRootViewController(animated: animated) != nil
    }
}
