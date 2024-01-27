//
//  SheetPresentationDetents.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import SwiftUI

public enum SheetPresentationDetent {
    case large
    case medium

    @available(iOS 16.0, *)
    var presentationDetent: PresentationDetent {
        switch self {
        case .large: .large
        case .medium: .medium
        }
    }
}

private struct SheetPresentationDetents: ViewModifier {
    let detents: [SheetPresentationDetent]

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents(presentationDetents)
        } else {
            content
        }
    }

    @available(iOS 16.0, *)
    private var presentationDetents: Set<PresentationDetent> {
        let presentationDetents = detents.map { detent in
            detent.presentationDetent
        }
        return Set(presentationDetents)
    }
}

extension View {
    public func sheetPresentationDetents(_ detents: [SheetPresentationDetent]) -> some View {
        modifier(SheetPresentationDetents(detents: detents))
    }
}
