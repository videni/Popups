//
//  LocalConfig+Anchored.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI

@MainActor
public class LocalConfigAnchored: LocalConfig { required public init() {}
    // MARK: Active Variables
    public var popupPadding: EdgeInsets = GlobalConfigContainer.center.popupPadding
    public var cornerRadius: CGFloat = GlobalConfigContainer.center.cornerRadius
    public var backgroundColor: Color = GlobalConfigContainer.center.backgroundColor
    public var overlayColor: Color = GlobalConfigContainer.center.overlayColor
    public var isTapOutsideToDismissEnabled: Bool = true

    // MARK: Anchored-specific Variables
    public var originAnchor: PopupAnchorPoint = .bottom
    public var popupAnchor: PopupAnchorPoint = .top
    public var offset: CGPoint = .zero
    public var tapOutsideBehavior: TapOutsideBehavior = .dismiss
    public var edgePadding: CGFloat = 16
    public var constrainedEdges: Edge.Set = .horizontal

    // MARK: Inactive Variables (inherited from LocalConfig protocol)
    public var ignoredSafeAreaEdges: Edge.Set = []
    public var heightMode: HeightMode = .auto
    public var dragDetents: [DragDetent] = []
    public var isDragGestureEnabled: Bool = false
    public var dragGestureAreaSize: CGFloat = 0
}

// MARK: - Chained Modifiers
public extension LocalConfigAnchored {
    /// Sets the anchor point on the source view (where the popup originates from)
    func originAnchor(_ anchor: PopupAnchorPoint) -> Self { self.originAnchor = anchor; return self }

    /// Sets the anchor point on the popup itself (which point aligns with origin)
    func popupAnchor(_ anchor: PopupAnchorPoint) -> Self { self.popupAnchor = anchor; return self }

    /// Sets additional offset from the calculated position
    func offset(_ offset: CGPoint) -> Self { self.offset = offset; return self }

    /// Sets additional offset from the calculated position
    func offset(x: CGFloat = 0, y: CGFloat = 0) -> Self { self.offset = CGPoint(x: x, y: y); return self }

    /// Sets behavior when tapping outside the popup
    /// - Parameter behavior: The tap outside behavior (.none, .dismiss, .passThrough)
    func tapOutsideBehavior(_ behavior: TapOutsideBehavior) -> Self { self.tapOutsideBehavior = behavior; return self }

    /// Configures edge padding and which edges to constrain
    /// - Parameters:
    ///   - value: Padding value from screen edges
    ///   - edges: Which edges to constrain (.horizontal, .vertical, .all, or [] to disable)
    func edgePadding(_ value: CGFloat, edges: Edge.Set = .horizontal) -> Self {
        self.edgePadding = value
        self.constrainedEdges = edges
        return self
    }
}

// MARK: - Public Type Alias
public typealias AnchoredPopupConfig = LocalConfigAnchored
