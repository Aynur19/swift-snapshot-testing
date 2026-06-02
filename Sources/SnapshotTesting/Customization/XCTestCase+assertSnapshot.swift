//
//  XCTestCase+assertSnapshot.swift
//  swift-snapshot-testing
//
//  Created by Aynur Nasybullin on 02.06.2026.
//

#if os(iOS) || os(tv)
import XCTest
import SwiftUI
import UIKit

@MainActor
extension XCTestCase {
    public func assertSnapshot<ViewType: SwiftUI.View>(
        of view: ViewType,
        size: SnapshotSize,
        config: SnapshotTestConfiguration,
        line: UInt
    ) {
        for theme in config.themes {
            let traits = UITraitCollection(userInterfaceStyle: theme == .dark ? .dark : .light)

          let snapshotting: Snapshotting<ViewType, UIImage> =
              Snapshotting.image(
                  layout: SwiftUISnapshotLayout.fixed(
                      width: size.size.width,
                      height: size.size.height
                  ),
                  traits: traits
              )
          
            let failure = verifySnapshot(
                of: view,
                as: snapshotting,
                named: theme.rawValue,
                record: config.recordMode == .all ? true : nil,
                fileID: config.fileID,
                file: config.file,
                testName: config.testName,
                line: line
            )

            if let message = failure {
                generateCustomDiffIfNeeded(config: config, theme: theme)
                XCTFail(message, file: config.file, line: line)
            } else {
                removeArtifacts(config: config, name: "\(config.cleanTestName).\(theme.rawValue)")
            }
        }
    }
}
#endif
