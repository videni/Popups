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
    var anchorID: String? = nil  // ID for AnchorRegistry lookup
    var anchorFrame: CGRect? = nil  // Static anchor frame (alternative to anchorID)
    /// Returns the anchor frame - uses static frame if set, otherwise fetches from registry
    func getAnchorFrame() -> CGRect {
        if let staticFrame = anchorFrame {
            return staticFrame
        } else if let anchorID = anchorID {
            return AnchorRegistry.frame(forKey: anchorID)
        }
        return .zero
    }
    var originAnchor: PopupAnchorPoint = .bottom
    var popupAnchor: PopupAnchorPoint = .top
    var anchorOffset: CGPoint = .zero
    var isTapOutsidePassThroughEnabled: Bool = false
    // MARK: Transition
    var transition: AnyTransition? = nil
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

        // Vertical-specific properties (transition)
        if let verticalConfig = config as? LocalConfigVertical {
            self.transition = verticalConfig.transition
        }
    }
}
