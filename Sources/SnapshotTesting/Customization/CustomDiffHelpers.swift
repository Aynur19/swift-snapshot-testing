//
//  CustomDiffHelpers.swift
//  swift-snapshot-testing
//
//  Created by Aynur Nasybullin on 02.06.2026.
//

#if os(iOS) || os(tv)
import UIKit

public enum SnapshotTheme: String {
  case light
  case dark
}

public enum SnapshotDiffLayoutMode {
  case original
  case comparisonHorizontal
  case comparisonVertical
}

public struct SnapshotSize {
  public let size: CGSize
  
  public static func currentDevice(
    widthMultiplier: CGFloat = 1.0,
    heightMultiplier: CGFloat = 1.0
  ) -> Self {
    let base = UIScreen.main.bounds.size
    
    return SnapshotSize(size: CGSize(
      width: base.width * widthMultiplier,
      height: base.height * heightMultiplier
    ))
  }
  
  public static func custom(width: CGFloat, height: CGFloat) -> Self {
    SnapshotSize(size: CGSize(width: width, height: height))
  }
}

public struct SnapshotTestConfiguration {
  public let file: StaticString
  public let fileID: StaticString
  public let testName: String
  public let recordMode: SnapshotTestingConfiguration.Record
  public let diffLayoutMode: SnapshotDiffLayoutMode
  public let themes: [SnapshotTheme]
  public let autoDeleteIfSuccess: Bool
  
  public init(
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    testName: String = #function,
    recordMode: SnapshotTestingConfiguration.Record = SnapshotTestingConfiguration.Record.missing,
    diffLayoutMode: SnapshotDiffLayoutMode = SnapshotDiffLayoutMode.comparisonHorizontal,
    themes: [SnapshotTheme] = [.light, .dark],
    autoDeleteIfSuccess: Bool = true
  ) {
    self.file = file
    self.fileID = fileID
    self.testName = testName
    self.recordMode = recordMode
    self.diffLayoutMode = diffLayoutMode
    self.themes = themes
    self.autoDeleteIfSuccess = autoDeleteIfSuccess
  }
  
  public var fileUrl: URL {
    URL(fileURLWithPath: "\(file)")
  }
  
  public var artifactRoot: URL {
    fileUrl
      .deletingLastPathComponent()
      .appendingPathComponent("SnapshotArtifacts")
  }
  
  public var artifactClass: URL {
    artifactRoot.appendingPathComponent(fileName)
  }
  
  public var fileName: String {
    fileUrl
      .deletingPathExtension()
      .lastPathComponent
  }
  
  public var cleanTestName: String {
    testName
      .components(separatedBy: "(")
      .first ?? testName
  }
}

func generateCustomDiffIfNeeded(config: SnapshotTestConfiguration, theme: SnapshotTheme) {
  let classFolder = config.artifactClass
  let prefix = "\(config.cleanTestName).\(theme.rawValue)"
  
  let referenceURL = classFolder.appendingPathComponent("\(prefix)_reference.png")
  let failureURL = classFolder.appendingPathComponent("\(prefix)_failure.png")
  let diffURL = classFolder.appendingPathComponent("\(prefix)_diff.png")
  
  guard let reference = UIImage(contentsOfFile: referenceURL.path),
        let failure = UIImage(contentsOfFile: failureURL.path),
        let originalDiff = UIImage(contentsOfFile: diffURL.path)
  else { return }
  
  let result: UIImage
  
  switch config.diffLayoutMode {
    case .original:
      return
    
   case .comparisonHorizontal:
      result = buildHorizontalDiff(reference: reference, failure: failure, diff: originalDiff)
      
    case .comparisonVertical:
      result = buildVerticalDiff(reference: reference, failure: failure, diff: originalDiff)
  }
  
  guard let data = result.pngData() else {
    return
  }
  
  let customDiffURL = classFolder.appendingPathComponent("\(prefix)_comparison.png")
  try? data.write(to: customDiffURL)
}

private func buildHorizontalDiff(reference: UIImage, failure: UIImage, diff: UIImage) -> UIImage {
  let width = max(reference.size.width, failure.size.width, diff.size.width)
  let height = max(reference.size.height, failure.size.height, diff.size.height)
  let scale = max(reference.scale, failure.scale, diff.scale)
  
  let canvasSize = CGSize(width: width * 3, height: height)
  
  UIGraphicsBeginImageContextWithOptions(canvasSize, true, scale)
  UIColor.white.setFill()
  UIRectFill(CGRect(origin: .zero, size: canvasSize))
  
  reference.draw(in: CGRect(
    x: 0,
    y: 0,
    width: reference.size.width,
    height: reference.size.height
  ))
  
  failure.draw(in: CGRect(
    x: width,
    y: 0,
    width: failure.size.width,
    height: failure.size.height
  ))
  
  diff.draw(in: CGRect(
    x: width * 2,
    y: 0,
    width: diff.size.width,
    height: diff.size.height
  ))
  
  let image = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  
  return image
}

private func buildVerticalDiff(reference: UIImage, failure: UIImage, diff: UIImage) -> UIImage {
  let width = max(reference.size.width, failure.size.width, diff.size.width)
  let height = max(reference.size.height, failure.size.height, diff.size.height)
  let scale = max(reference.scale, failure.scale, diff.scale)
  
  let canvasSize = CGSize(width: width, height: height * 3)
  
  UIGraphicsBeginImageContextWithOptions(canvasSize, true, scale)
  UIColor.white.setFill()
  UIRectFill(CGRect(origin: .zero, size: canvasSize))
  
  reference.draw(in: CGRect(
    x: 0,
    y: 0,
    width: reference.size.width,
    height: reference.size.height
  ))
  
  failure.draw(in: CGRect(
    x: 0,
    y: height,
    width: failure.size.width,
    height: failure.size.height
  ))
  
  diff.draw(in: CGRect(
    x: 0,
    y: height * 2,
    width: diff.size.width,
    height: diff.size.height
  ))
  
  let image = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  
  return image
}

func removeArtifacts(config: SnapshotTestConfiguration, name: String) {
  let classFolder = config.artifactClass
  
  guard let files = try? FileManager.default.contentsOfDirectory(
    at: classFolder,
    includingPropertiesForKeys: nil
  ) else { return }
  
  for file in files {
    guard file.lastPathComponent.hasPrefix(name) else {
      continue
    }
    
    try? FileManager.default.removeItem(at: file)
  }
  
  removeClassFolderIfEmpty(folder: config.artifactClass)
}

private func removeClassFolderIfEmpty(folder: URL) {
  guard let files = try? FileManager.default.contentsOfDirectory(
    at: folder, includingPropertiesForKeys: nil
  ) else { return }
  
  guard files.isEmpty else { return }
  
  try? FileManager.default.removeItem(at: folder)
}
#endif
