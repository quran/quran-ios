import Foundation
import QuranKit
import TestResources
import UIKit

/// Writes black line images and the test line-page database where `LinePageAssetService` looks for them.
func makeLinePageFiles(metrics: LinePageMetrics) throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let images = root.appendingPathComponent("images_\(metrics.widthParameter)")
    let database = images.appendingPathComponent("databases")
    let lines = images.appendingPathComponent("width_\(metrics.widthParameter)/1")
    try FileManager.default.createDirectory(at: database, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: lines, withIntermediateDirectories: true)
    try FileManager.default.copyItem(
        at: TestResources.resourceURL("line_page_ayahinfo.db"),
        to: database.appendingPathComponent("ayahinfo_\(metrics.widthParameter).db")
    )
    let imageSize = CGSize(width: CGFloat(metrics.widthParameter), height: CGFloat(metrics.intrinsicLineHeight))
    let image = UIGraphicsImageRenderer(size: imageSize).pngData { context in
        UIColor.black.setFill()
        context.fill(CGRect(origin: .zero, size: imageSize))
    }
    for line in 1 ... metrics.lineCount {
        try image.write(to: lines.appendingPathComponent("\(line).png"))
    }
    return root
}
