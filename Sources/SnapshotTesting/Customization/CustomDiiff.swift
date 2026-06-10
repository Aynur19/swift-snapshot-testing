//
//  CustomDiiff.swift
//  swift-snapshot-testing
//
//  Created by Aynur Nasybullin on 02.06.2026.
//

#if os(iOS) || os(tvOS)
import UIKit

func diff(colors: SnapshotDiffRGBAColors, old: UIImage, new: UIImage) -> UIImage {
  guard let oldCG = old.cgImage,
        let newCG = new.cgImage
  else { return new }

  let scale = max(old.scale, new.scale)
  let width = max(oldCG.width, newCG.width)
  let height = max(oldCG.height, newCG.height)
  
  let bytesPerPixel = 4
  let bytesPerRow = width * bytesPerPixel
  let totalBytes = height * bytesPerRow
  
  var oldPixels = [UInt8](repeating: 0, count: totalBytes)
  var newPixels = [UInt8](repeating: 0, count: totalBytes)
  
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  
  guard prepareBeforeDiff(
    width: width,
    height: height,
    bytesPerRow: bytesPerRow,
    colorSpace: colorSpace,
    oldCG: oldCG,
    newCG: newCG,
    oldPixels: &oldPixels,
    newPixels: &newPixels
  ) else { return new }
  
  var diffPixels = performPixels(
    colors: colors,
    width: width,
    height: height,
    bytesPerRow: bytesPerRow,
    oldPixels: oldPixels,
    newPixels: newPixels
  )
  
  guard
    let diffContext = CGContext(
      data: &diffPixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ),
    let diffCG = diffContext.makeImage()
  else { return new }
  
  return UIImage(cgImage: diffCG, scale: scale, orientation: .up)
}

private func prepareBeforeDiff(
  width: Int,
  height: Int,
  bytesPerRow: Int,
  colorSpace: CGColorSpace,
  oldCG: CGImage,
  newCG: CGImage,
  oldPixels: inout [UInt8],
  newPixels: inout [UInt8]
) -> Bool {
  guard
    let oldContext = CGContext(
      data: &oldPixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ),
    let newContext = CGContext(
      data: &newPixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { return false }
  
  oldContext.clear(CGRect(x: 0, y: 0, width: width, height: height))
  newContext.clear(CGRect(x: 0, y: 0, width: width, height: height))
  
  oldContext.draw(oldCG, in: CGRect(
    x: 0,
    y: height - oldCG.height,
    width: oldCG.width,
    height: oldCG.height
  ))
  
  newContext.draw(newCG, in: CGRect(
    x: 0,
    y: height - newCG.height,
    width: newCG.width,
    height: newCG.height
  ))
  
  return true
}

private func performPixels(
  colors: SnapshotDiffRGBAColors,
  width: Int,
  height: Int,
  bytesPerRow: Int,
  oldPixels: [UInt8],
  newPixels: [UInt8]
) -> [UInt8] {
  var result = [UInt8](repeating: 0, count: height * bytesPerRow)
  let width4 = width * 4
  
  result.withUnsafeMutableBufferPointer { resultPtr in
    oldPixels.withUnsafeBufferPointer { oldPtr in
      newPixels.withUnsafeBufferPointer { newPtr in
        let baseRes = resultPtr.baseAddress!
        let baseOld = oldPtr.baseAddress!
        let baseNew = newPtr.baseAddress!
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
          let rowOffset = y * bytesPerRow
          let resRow = baseRes.advanced(by: rowOffset)
          let oldRow = baseOld.advanced(by: rowOffset)
          let newRow = baseNew.advanced(by: rowOffset)
          
          var x = 0
          while x < width4 {
            let oldA = oldRow[x + 3]
            let newA = newRow[x + 3]
            
            if oldA > 0 && newA > 0 {
              let dr = fastDiff(oldRow[x], newRow[x])
              let dg = fastDiff(oldRow[x+1], newRow[x+1])
              let db = fastDiff(oldRow[x+2], newRow[x+2])
              
              let delta = max(dr, max(dg, db))
              
              if delta <= 1 {
                resRow.setColor(pixel: x, color: colors.perfectMatch)
              } else if delta <= 25 {
                resRow.setColor(pixel: x, color: colors.weakDiff)
              } else if delta <= 80 {
                resRow.setColor(pixel: x, color: colors.moderateDiff)
              } else {
                resRow.setColor(pixel: x, color: colors.strongDiff)
              }
            } else if oldA == 0 || newA == 0 {
              resRow.setColor(pixel: x, color: colors.noPixel)
            } else if oldA == 0 && newA == 0 {
              resRow.setColor(pixel: x, color: colors.perfectMatch)
            }
            
            x += 4
          }
        }
      }
    }
  }
  
  return result
}

@inline(__always)
private func fastDiff(_ a: UInt8, _ b: UInt8) -> UInt8 {
  a > b ? a - b : b - a
}

extension UnsafeMutablePointer<UInt8> {
  func setColor(pixel: Int, color: RGBAColor) {
    self[pixel]     = color.red
    self[pixel + 1] = color.green
    self[pixel + 2] = color.blue
    self[pixel + 3] = color.alpha
  }
}
#endif
