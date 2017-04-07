//
//  ReusableView.swift
//  GenericDataSource
//
//  Created by Mohamed Ebrahim Mohamed Afifi on 3/27/17.
//  Copyright © 2017 mohamede1945. All rights reserved.
//

/// The base protocol for any reusable view whether it is a cell or a supplementary view.
/// It is used to give default reuse identifier and nib name.
@objc public protocol ReusableView {
}

extension ReusableView {

    /// Represents a default reuse id. It is the class name as string.
    /// Usually (99.99% of the times) we register the cell once. So a unique name would be the reuse id.
    public static var ds_reuseId: String {
        return String(describing: self)
    }

    /// Represents a default nib name. It is the class name as string.
    /// Usually (99.99% of the times) we name the nib as the class name.
    public static var ds_nibName: String {
        return String(describing: self)
    }
}
