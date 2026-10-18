//
//  Icons.swift
//  BakeCheck
//
//  The web prototype shipped a hand-rolled SVG icon set. On iOS the native
//  equivalent is SF Symbols, so each logical icon maps to a symbol name.
//

import SwiftUI

enum IconName: String, Hashable, CaseIterable {
    case dashboard = "square.grid.2x2"
    case orders = "list.bullet.rectangle"
    case scan = "viewfinder"
    case history = "clock.arrow.circlepath"
    case settings = "slider.horizontal.3"
    case search = "magnifyingglass"
    case bell = "bell"
    case plus = "plus"
    case minus = "minus"
    case arrowRight = "arrow.right"
    case arrowLeft = "arrow.left"
    case chevronRight = "chevron.right"
    case check = "checkmark"
    case checkCircle = "checkmark.circle"
    case xmark = "xmark"
    case xCircle = "xmark.circle"
    case alertTriangle = "exclamationmark.triangle"
    case alertCircle = "exclamationmark.circle"
    case info = "info.circle"
    case camera = "camera"
    case refresh = "arrow.clockwise"
    case edit = "square.and.pencil"
    case package = "shippingbox"
    case truck = "truck.box"
    case menu = "line.3.horizontal"
    case lock = "lock"
    case user = "person"
    case store = "storefront"
    case clock = "clock"
    case shield = "checkmark.shield"
    case flask = "testtube.2"
    case inbox = "tray"
    case warning = "exclamationmark.triangle.fill"
}

struct Icon: View {
    var name: IconName
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: name.rawValue)
            .font(.system(size: size, weight: .medium))
            .symbolRenderingMode(.monochrome)
            .accessibilityHidden(true)
    }
}
