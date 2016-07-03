//
//  ShareController.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class ShareController: NSObject {


    class func showShareActivityWithText(text: String, image: UIImage! = nil, url: NSURL! = nil, sourceViewController: UIViewController, handler: UIActivityViewControllerCompletionWithItemsHandler!) {
        var itemsToShare = [AnyObject]()
        itemsToShare.append(text)
        if image != nil {
            itemsToShare.append(image)
        }
        if url != nil {
            itemsToShare.append(url)
        }

        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        if let handler = handler {
            activityViewController.completionWithItemsHandler = handler
        }


        sourceViewController.presentViewController(activityViewController, animated: true, completion: nil)

    }
}
