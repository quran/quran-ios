import SwiftUI

enum AudioControlMetrics {
    static let minimumTapLength: CGFloat = 44
}

struct AudioControlLabel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(minWidth: AudioControlMetrics.minimumTapLength, minHeight: AudioControlMetrics.minimumTapLength)
            .contentShape(Rectangle())
    }
}

struct AudioControlButton: View {
    let image: NoorSystemImage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AudioControlLabel {
                image.image
            }
        }
    }
}
