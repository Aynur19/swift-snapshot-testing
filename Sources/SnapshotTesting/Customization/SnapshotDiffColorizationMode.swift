//
//  SnapshotDiffColorizationMode.swift
//  swift-snapshot-testing
//
//  Created by Aynur Nasybullin on 03.06.2026.
//

#if os(iOS) || os(tv)
public struct RGBAColor {
  public let red: UInt8
  public let green: UInt8
  public let blue: UInt8
  public let alpha: UInt8
  
  public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}

public struct SnapshotDiffRGBAColors {
  public let noPixel: RGBAColor
  public let perfectMatch: RGBAColor
  public let weakDiff: RGBAColor
  public let moderateDiff: RGBAColor
  public let strongDiff: RGBAColor
  
  public init(
    noPixel: RGBAColor,
    perfectMatch: RGBAColor,
    weakDiff: RGBAColor,
    moderateDiff: RGBAColor,
    strongDiff: RGBAColor
  ) {
    self.noPixel = noPixel
    self.perfectMatch = perfectMatch
    self.weakDiff = weakDiff
    self.moderateDiff = moderateDiff
    self.strongDiff = strongDiff
  }
}

extension SnapshotDiffRGBAColors {
  public static let `default` = SnapshotDiffRGBAColors(
    noPixel:      RGBAColor(red: 180, green: 100, blue: 255, alpha: 255),   // pink
    perfectMatch: RGBAColor(red: 255, green: 255, blue: 255, alpha: 255),   // white
    weakDiff:     RGBAColor(red: 255, green: 210, blue: 230, alpha: 255),   // light pink
    moderateDiff: RGBAColor(red: 255, green: 180, blue: 90, alpha: 255),    // orange
    strongDiff:   RGBAColor(red: 255, green: 80, blue: 80, alpha: 255),     // red
  )
}

public enum SnapshotDiffColorizationMode {
  case original
  case custom(colors: SnapshotDiffRGBAColors)
}

extension SnapshotDiffColorizationMode {
  public static var isCustom: Bool {
    switch current {
      case .original: false
      case .custom:   true
    }
  }
  
  public static var current: Self = SnapshotDiffColorizationMode.custom(
    colors: SnapshotDiffRGBAColors.default
  )
}
#endif
