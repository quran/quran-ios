//
//  WordFrameCollection+Extension.swift
//
//
//  Created by Mohamed Afifi on 2024-04-07.
//

import Foundation
import QuranGeometry
import QuranKit

extension WordFrameCollection {
    public func wordAtLocation(_ location: CGPoint, imageScale: WordFrameScale) -> Word? {
        let flattenFrames = lines.flatMap { $0 }
        for frame in flattenFrames {
            let rectangle = frame.rect.scaled(by: imageScale)
            if rectangle.contains(location) {
                return frame.word
            }
        }
        return nil
    }
}
