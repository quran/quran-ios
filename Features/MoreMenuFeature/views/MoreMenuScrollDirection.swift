//
//  MoreMenuScrollDirection.swift
//
//
//  Created by Adnan on 09/12/24.
//

import Localization
import SwiftUI

/// A segmented control for selecting scroll direction (horizontal/vertical) in Translation mode.
struct MoreMenuScrollDirection: View {
    @Binding var verticalScrollingEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(l("menu.scroll_direction"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 12)
            
            Picker(selection: $verticalScrollingEnabled, label: Text("")) {
                // Horizontal scrolling option
                Text("\(l("menu.scroll_horizontal")) ⇄")
                    .tag(false)
                
                // Vertical scrolling option
                Text("\(l("menu.scroll_vertical")) ⇅")
                    .tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color.systemBackground)
    }
}

// MARK: - Legacy Compatibility

/// Keep the old name for compatibility but forward to the new implementation
struct MoreMenuVerticalScrolling: View {
    @Binding var enabled: Bool
    
    var body: some View {
        MoreMenuScrollDirection(verticalScrollingEnabled: $enabled)
    }
}

// MARK: - Preview

struct MoreMenuScrollDirection_Previews: PreviewProvider {
    struct Container: View {
        @State var verticalEnabled: Bool
        
        var body: some View {
            MoreMenuScrollDirection(verticalScrollingEnabled: $verticalEnabled)
        }
    }
    
    static var previews: some View {
        VStack(spacing: 20) {
            Container(verticalEnabled: false)
            Divider()
            Container(verticalEnabled: true)
        }
        .previewLayout(.sizeThatFits)
    }
}
