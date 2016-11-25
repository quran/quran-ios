//
//  ShareController.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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
