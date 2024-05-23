//
//  WordFrameLine.swift
//
//
//  Created by Mohamed Afifi on 2024-05-20.
//

public struct WordFrameLine: Hashable {
    public var frames: [WordFrame]

    public init(frames: [WordFrame]) {
        self.frames = frames
    }
}
