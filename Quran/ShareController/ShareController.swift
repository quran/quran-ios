//
//  ShareController.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit

class ShareController: NSObject {

    class func showShareActivityWithText(_ text: String, image: UIImage? = nil, url: URL? = nil,
                                         sourceViewController: UIViewController,
                                         handler: UIActivityViewControllerCompletionWithItemsHandler?) {
        var itemsToShare = [AnyObject]()
        itemsToShare.append(text as AnyObject)
        if let shareImage = image {
            itemsToShare.append(shareImage)
        }
        if let shareURL = url {
            itemsToShare.append(shareURL as AnyObject)
        }

        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = handler
        sourceViewController.present(activityViewController, animated: true, completion: nil)
    }
}
