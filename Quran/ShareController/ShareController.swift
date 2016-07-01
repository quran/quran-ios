//
//  ShareController.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class ShareController: NSObject {


    class func showShareActivityWithText(text: String, image: UIImage? = nil, url: NSURL? = nil,
                                         sourceViewController: UIViewController,
                                         handler: UIActivityViewControllerCompletionWithItemsHandler!) {
        var itemsToShare = [AnyObject]()
        itemsToShare.append(text)
        if let shareImage = image {
            itemsToShare.append(shareImage)
        }
        if let shareURL = url {
            itemsToShare.append(shareURL)
        }

        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = handler
        sourceViewController.presentViewController(activityViewController, animated: true, completion: nil)
    }
}
