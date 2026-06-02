//
//  File.swift
//  swift-snapshot-testing
//
//  Created by Aynur Nasybullin on 02.06.2026.
//

#if os(iOS) || os(tvOS)
import UIKit

public enum SnapshotDiffColorization {
  case original
  case custom
  
  public static var current: Self = .custom
}

func diff(old: UIImage, new: UIImage) -> UIImage {
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
  var diffPixels = [UInt8](repeating: 0, count: totalBytes)
  
  guard
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
    
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
  else {
    return new
  }
  
  oldContext.setFillColor(UIColor.clear.cgColor)
  oldContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
  
  newContext.setFillColor(UIColor.clear.cgColor)
  newContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
  
  // ВАЖНО:
  // рисуем в левый верхний угол
  // поэтому недостающая область оказывается справа/снизу
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
  
  for pixel in stride(from: 0, to: totalBytes, by: 4) {
    let oldR = oldPixels[pixel]
    let oldG = oldPixels[pixel + 1]
    let oldB = oldPixels[pixel + 2]
    let oldA = oldPixels[pixel + 3]
    
    let newR = newPixels[pixel]
    let newG = newPixels[pixel + 1]
    let newB = newPixels[pixel + 2]
    let newA = newPixels[pixel + 3]
    
    let oldExists = oldA > 0
    let newExists = newA > 0
    
    let color: (UInt8, UInt8, UInt8)
    
    switch (oldExists, newExists) {
      case (false, false):
        color = (255, 255, 255)
        
      case (true, false), (false, true):
        color = (180, 100, 255) // Фиолетовый
        
      case (true, true):
        let delta = max(
          abs(Int(oldR) - Int(newR)),
          abs(Int(oldG) - Int(newG)),
          abs(Int(oldB) - Int(newB))
        )
        
        switch delta {
          case 0...5:   color = (255, 255, 255)   // Белый
          case 6...25:  color = (255, 210, 230)   // Светло-розовый
          case 26...80: color = (255, 180, 90)    // Оранжевый
          default:      color = (255, 80, 80)     // Красный
        }
    }
    
    diffPixels[pixel] = color.0
    diffPixels[pixel + 1] = color.1
    diffPixels[pixel + 2] = color.2
    diffPixels[pixel + 3] = 255
  }
  
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
  else {
    return new
  }
  
  return UIImage(cgImage: diffCG, scale: scale, orientation: .up)
}
#endif
