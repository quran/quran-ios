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

// MARK: - APIs

public extension ViewControllable {
    func present(_ viewController: ViewControllable, animated: Bool, completion: (() -> Void)? = nil) {
        uiviewController.present(viewController.uiviewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        uiviewController.dismiss(animated: animated, completion: completion)
    }

    func addFullScreenChild(_ viewController: ViewControllable) {
        uiviewController.addFullScreenChild(viewController.uiviewController)
    }

    func removeChild(_ viewController: ViewControllable) {
        uiviewController.removeChild(viewController.uiviewController)
    }
}
