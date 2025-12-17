//
//  AnyPopupConfig.swift of MijickPopups
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

/// Wrapper to bypass Sendable compiler checks for anchor frame closure.
///
/// This is safe because:
/// 1. The closure only captures @State variables which are main-thread isolated in SwiftUI
/// 2. The closure is only called from UI layer (main thread) in calculatePopupPosition()
/// 3. No actual cross-thread access occurs - the Sendable requirement is only for
///    passing AnyPopup through async boundaries, not for concurrent execution
struct AnchorFrameProvider: @unchecked Sendable {
    let closure: () -> CGRect
    func callAsFunction() -> CGRect { closure() }
}

struct AnyPopupConfig: LocalConfig, Sendable { init() {}
    // MARK: Content
    var alignment: PopupAlignment = .center
    var popupPadding: EdgeInsets = .init()
    var cornerRadius: CGFloat = 0
    var ignoredSafeAreaEdges: Edge.Set = []
    var backgroundColor: Color = .clear
    var overlayColor: Color = .clear
    var heightMode: HeightMode = .auto
    var dragDetents: [DragDetent] = []

    // MARK: Gestures
    var isTapOutsideToDismissEnabled: Bool = false
    var isDragGestureEnabled: Bool = false
    var dragGestureAreaSize: CGFloat = 0

    // MARK: Anchored-specific
    var anchorFrameProvider: AnchorFrameProvider? = nil
    var anchorFrame: CGRect { anchorFrameProvider?() ?? .zero }
    var originAnchor: PopupAnchorPoint = .bottom
    var popupAnchor: PopupAnchorPoint = .top
    var anchorOffset: CGPoint = .zero
    var isTapOutsidePassThroughEnabled: Bool = false
    var edgePadding: CGFloat = 16
    var constrainedEdges: Edge.Set = .horizontal
}

// MARK: Initialize
extension AnyPopupConfig {
    init<Config: LocalConfig>(_ config: Config) {
        self.alignment = .init(Config.self)
        self.popupPadding = config.popupPadding
        self.cornerRadius = config.cornerRadius
        self.ignoredSafeAreaEdges = config.ignoredSafeAreaEdges
        self.backgroundColor = config.backgroundColor
        self.overlayColor = config.overlayColor
        self.heightMode = config.heightMode
        self.dragDetents = config.dragDetents
        self.isTapOutsideToDismissEnabled = config.isTapOutsideToDismissEnabled
        self.isDragGestureEnabled = config.isDragGestureEnabled
        self.dragGestureAreaSize = config.dragGestureAreaSize

        // Anchored-specific properties
        if let anchoredConfig = config as? LocalConfigAnchored {
            self.originAnchor = anchoredConfig.originAnchor
            self.popupAnchor = anchoredConfig.popupAnchor
            self.anchorOffset = anchoredConfig.offset
            self.isTapOutsidePassThroughEnabled = anchoredConfig.isTapOutsidePassThroughEnabled
            self.edgePadding = anchoredConfig.edgePadding
            self.constrainedEdges = anchoredConfig.constrainedEdges
        }
    }
}
