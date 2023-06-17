//
//  Previewing.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
public struct Previewing {
    public static func list(@ViewBuilder content: @escaping () -> some View) -> some View {
        Group {
            ForEach([ColorScheme.light, ColorScheme.dark], id: \.self) { scheme in
                ScrollView {
                    ForEach(0 ..< 10) { _ in
                        VStack {
                            ForEach([ContentSizeCategory.large, .extraExtraLarge], id: \.self) { size in
                                content()
                                    .environment(\.sizeCategory, size)
                            }
                        }
                    }
                }
                .previewLayout(.fixed(width: 400, height: 600))
                .background(Color(UIColor.systemBackground))
                .colorScheme(scheme)
            }
        }
    }

    public static func screen(
        schemes: [ColorScheme] = [.light, .dark],
        sizes: [ContentSizeCategory] = [.large, .extraExtraLarge],
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        Group {
            ForEach(schemes, id: \.self) { scheme in
                ForEach(sizes, id: \.self) { size in
                    content()
                        .environment(\.sizeCategory, size)
                }
                .background(
                    Color.systemBackground
                        .edgesIgnoringSafeArea(.all)
                )
                .colorScheme(scheme)
            }
        }
    }

    public static func rightToLeft(@ViewBuilder content: @escaping () -> some View) -> some View {
        Group {
            content()
                .environment(\.layoutDirection, .leftToRight)
            content()
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
