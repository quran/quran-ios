//
//  AppStoreDownloadButton.swift
//
//
//  Created by Mohamed Afifi on 2023-06-28.
//

import SwiftUI
import UIx

public enum DownloadType {
    case pending
    case downloading(progress: Double)
    case download
}

struct AppStoreDownloadButton: View {
    @ScaledMetric private var length = 26

    let type: DownloadType
    let action: AsyncAction

    var body: some View {
        AsyncButton(action: action) {
            Group {
                switch type {
                case .pending:
                    CircularPendingView()
                case .downloading(let progress):
                    CircularDownloadingView(progress: progress)
                case .download:
                    NoorSystemImage.download.image
                        .renderingMode(.template)
                        .foregroundColor(.accentColor)
                }
            }
            .frame(width: length, height: length)
        }
        .buttonStyle(.borderless)
    }
}

struct CircularPendingView: View {
    var body: some View {
        Arc(circlePercentage: 0.94)
            .stroke(Color.accentColor, lineWidth: lineWidth)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }

    @State private var isAnimating = false
    @ScaledMetric private var lineWidth: Double = 1
}

struct CircularDownloadingView: View {
    @ScaledMetric private var stopLength = 8
    @ScaledMetric private var lineWidth: Double = 1
    @ScaledMetric private var fillLineWidth: Double = 4

    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor, lineWidth: lineWidth)

            Arc(circlePercentage: progress)
                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: fillLineWidth, lineCap: .butt))

            Rectangle()
                .fill(Color.accentColor)
                .frame(width: stopLength, height: stopLength)
        }
    }
}

struct AppStoreDownloadButton_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Group {
                AppStoreDownloadButton(type: .pending) { }
                AppStoreDownloadButton(type: .downloading(progress: 0.3)) { }
                AppStoreDownloadButton(type: .download) { }
                AppStoreDownloadButton(type: .downloading(progress: 0.9)) { }
            }
            .padding()
            .border(Color.red)
        }
    }
}
