//
//  HighlightingView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

// This class is expected to be implemented using CoreAnimation with CAShapeLayers.
// It's also expected to reuse layers instead of dropping & creating new ones.
class HighlightingView: UIView {

    @IBInspectable var highlightColor: UIColor = UIColor.appIdentity().colorWithAlphaComponent(0.25)

    /// is true when user long pressed on verse to select and a menu controller is displayed.
    var isSelectingVerse = false
    
    var highlightedAyat: Set<AyahNumber> = Set<AyahNumber>() {
        didSet {
            updateRectangleBounds()
        }
    }

    var ayahInfoData: [AyahNumber: [AyahInfo]]? {
        didSet {
            updateRectangleBounds()
        }
    }

    private var imageScale: CGFloat = 0.0
    private var xOffset: CGFloat = 0.0
    private var yOffset: CGFloat = 0.0

    var highlightingRectangles: [CGRect] = []

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard highlightedAyat.count > 0 else { return }

        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, highlightColor.CGColor)
        for rect in highlightingRectangles {
            CGContextFillRect(context, rect)
        }
    }

    func setScaleInfo(scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        self.imageScale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset

        updateRectangleBounds()
    }

    func reset() {
        highlightedAyat = Set<AyahNumber>()
        ayahInfoData = nil
        imageScale = 0.0
        xOffset = 0.0
        yOffset = 0.0
        isSelectingVerse = false
    }

    private func updateRectangleBounds() {

        highlightingRectangles.removeAll(keepCapacity: true)
        for ayah in highlightedAyat {
            guard let ayahInfo = ayahInfoData?[ayah] else { continue }

            for piece in ayahInfo {
                let rectangle = piece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
                highlightingRectangles.append(rectangle)
            }
        }

        setNeedsDisplay()
    }
    
    //MARK: - Highlighting Verse on touch -
    
    func deselectTheSelectedVerse(){
        // set no highlighed ayaat
        highlightedAyat = Set<AyahNumber>()
        isSelectingVerse = false
        
        // hide the menu controller
        UIMenuController.sharedMenuController().setMenuVisible(false, animated: true)
    }
    
    /**
     Highlight a verse that contains a given touch location. The verse will be highlighted and a menu controller will be displayed with options like Copy and Share the verse.
     - Parameter location: The touch location where we check the verse that match the location to highlight
     - Returns: true if a verse is found and match the location, false otherwise.
     */
    func highlightVerseAtLocation(location: CGPoint) -> Bool{
        
        if let ayah = ayahNumberForTouchLocation(location){
            var set = Set<AyahNumber>()
            set.insert(ayah)
            self.highlightedAyat = set
            
            guard let ayahInfo = ayahInfoData?[ayah] else { return true}
            if let firstPiece = ayahInfo.first{
                let rectangle = firstPiece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
                
                showMenuControllerAtRect(rectangle)
                isSelectingVerse = true
            }
            
            return true
        }
        return false
    }
    
    
    private func ayahNumberForTouchLocation(location: CGPoint) -> AyahNumber!{
        if let ayahInfoData = self.ayahInfoData{
            for (ayahNumber, ayahInfo) in ayahInfoData{
                for piece in ayahInfo{
                    let rectangle = piece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
                    if rectangle.contains(location){
                        return ayahNumber
                    }
                }
            }
        }
        
        return nil
    }
    
    //MARK: - Menu Controller (Clipboard) -
    
    private func showMenuControllerAtRect(rect: CGRect){
        self.becomeFirstResponder()
        UIMenuController.sharedMenuController().setTargetRect(rect, inView: self)
        UIMenuController.sharedMenuController().setMenuVisible(true, animated: true)
    }
    
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        print(action)
        if action == Selector("copy:") || action == Selector("_share:"){
            return true
        }
        return false
    }
    
    override func copy(sender: AnyObject?) {
        let pasteBoard = UIPasteboard.generalPasteboard()
        pasteBoard.string = "Aya text goes here"
    }
    
    
    func _share(sender: AnyObject?){
        print("Sharing goes here!")
    }
    
}
