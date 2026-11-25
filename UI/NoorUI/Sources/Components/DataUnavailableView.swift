//
//  DataUnavailableView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Localization
import SwiftUI

public struct DataUnavailableView: View {
    // MARK: Lifecycle

    public init(title: String, text: String, image: NoorSystemImage) {
        self.title = title
        self.text = text
        self.image = image
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { proxy in
            VStack {
                image.image
                    .font(.largeTitle)
                    .imageScale(.large)
                Text(title)
                    .font(.headline)
                    .padding()
                Text(text)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.secondaryLabel)
            .padding(.horizontal)
            .offset(y: proxy.size.height / 4)
            .frame(maxWidth: .infinity)
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        // Respect the side safe areas so the text stays clear of side bars, like
        // the vertical tab bar and status bar on iPhone Duo's outer display.
        .ignoresSafeArea(.all, edges: .vertical)
    }

    // MARK: Internal

    let title: String
    let text: String
    let image: NoorSystemImage
}

struct DataUnavailableView_Previews: PreviewProvider {
    static var previews: some View {
        DataUnavailableView(
            title: l("bookmarks.no-data.title"),
            text: l("bookmarks.no-data.text"),
            image: .bookmark
        )
    }
}
