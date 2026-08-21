import Localization
import SwiftUI

struct MoreMenuLinePageDisplay: View {
    @Binding var showDividers: Bool
    @Binding var showSidelines: Bool

    var body: some View {
        VStack(spacing: 0) {
            Toggle(l("menu.linePageDividers"), isOn: $showDividers)
                .padding()

            Divider()
                .padding(.leading)

            Toggle(l("menu.linePageSidelines"), isOn: $showSidelines)
                .padding()
        }
    }
}

#Preview {
    MoreMenuLinePageDisplay(
        showDividers: .constant(true),
        showSidelines: .constant(true)
    )
}
