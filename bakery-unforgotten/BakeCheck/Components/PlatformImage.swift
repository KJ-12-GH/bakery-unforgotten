//
//  PlatformImage.swift
//  BakeCheck
//
//  Tiny UIKit/AppKit shim so the camera thumbnail code compiles on both iOS
//  and macOS (the target declares support for both).
//

import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage
#endif

func capturedImage(from data: Data) -> PlatformImage? {
    PlatformImage(data: data)
}

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}
