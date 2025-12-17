//
//  ViewModel+AnchoredStack.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI

extension VM { class AnchoredStack: ViewModel { required init() {}
    var alignment: PopupAlignment = .anchored
    var popups: [AnyPopup] = []
    var activePopupProperties: ActivePopupProperties = .init()
    var screen: Screen = .init()
    var updatePopupAction: ((AnyPopup) async -> ())?
    var closePopupAction: ((AnyPopup) async -> ())?
}}


// MARK: - METHODS / VIEW MODEL / ACTIVE POPUP



// MARK: Height
extension VM.AnchoredStack {
    func calculateActivePopupHeight() async -> CGFloat? {
        popups.last?.height
    }
}

// MARK: Outer Padding
extension VM.AnchoredStack {
    func calculateActivePopupOuterPadding() async -> EdgeInsets { .init() }
}

// MARK: Inner Padding
extension VM.AnchoredStack {
    func calculateActivePopupInnerPadding() async -> EdgeInsets { .init() }
}

// MARK: Corners
extension VM.AnchoredStack {
    func calculateActivePopupCorners() async -> [PopupAlignment : CGFloat] { [
        .top: popups.last?.config.cornerRadius ?? 0,
        .bottom: popups.last?.config.cornerRadius ?? 0
    ]}
}

// MARK: Vertical Fixed Size
extension VM.AnchoredStack {
    func calculateActivePopupVerticalFixedSize() async -> Bool { true }
}

// MARK: Translation Progress
extension VM.AnchoredStack {
    func calculateActivePopupTranslationProgress() async -> CGFloat { 0 }
}


// MARK: - METHODS / VIEW MODEL / SELECTED POPUP



// MARK: Height
extension VM.AnchoredStack {
    func calculatePopupHeight(_ heightCandidate: CGFloat, _ popup: AnyPopup) async -> CGFloat {
        min(heightCandidate, calculateMaxHeight())
    }
}
private extension VM.AnchoredStack {
    func calculateMaxHeight() -> CGFloat {
        let fullscreenHeight = screen.height,
            safeAreaHeight = screen.safeArea.top + screen.safeArea.bottom
        return fullscreenHeight - safeAreaHeight
    }
}


// MARK: - METHODS / VIEW



// MARK: Opacity
extension VM.AnchoredStack {
    func calculateOpacity(for popup: AnyPopup) -> CGFloat {
        // AnchoredPopup supports multiple popups displayed simultaneously, so all popups have opacity 1
        1
    }
}

// MARK: Position Calculation
extension VM.AnchoredStack {
    /// Calculates the position for the popup based on anchor frame and anchor points
    func calculatePopupPosition(for popup: AnyPopup, popupSize: CGSize, containerSize: CGSize = .zero) -> CGPoint {
        let config = popup.config
        let anchorFrame = config.getAnchorFrame()

        // Calculate origin point on the anchor view
        let originPoint = calculateAnchorPoint(for: config.originAnchor, in: anchorFrame)

        // Calculate the offset needed based on popup anchor point
        let popupOffset = calculatePopupOffset(for: config.popupAnchor, popupSize: popupSize)

        // Initial position
        var popoverFrame = CGRect(
            x: originPoint.x - popupOffset.x + config.anchorOffset.x,
            y: originPoint.y - popupOffset.y + config.anchorOffset.y,
            width: popupSize.width,
            height: popupSize.height
        )

        // Apply boundary avoidance
        popoverFrame = applyBoundaryAvoidance(frame: popoverFrame, config: config, screenSize: containerSize)

        return popoverFrame.origin
    }

    /// Keeps popup within screen bounds based on configured edge constraints
    private func applyBoundaryAvoidance(frame: CGRect, config: AnyPopupConfig, screenSize: CGSize) -> CGRect {
        let edges = config.constrainedEdges

        // No constraints, return original frame
        guard !edges.isEmpty else { return frame }

        // Skip if screen size not initialized
        guard screenSize.width > 0, screenSize.height > 0 else { return frame }

        var popoverFrame = frame
        let padding = config.edgePadding

        // Horizontal constraint
        if edges.contains(.horizontal) {
            let minX = screen.safeArea.leading + padding
            let maxX = screenSize.width - screen.safeArea.trailing - padding

            // Left edge overflow
            if popoverFrame.origin.x < minX {
                popoverFrame.origin.x = minX
            }
            // Right edge overflow
            if popoverFrame.maxX > maxX {
                let difference = popoverFrame.maxX - maxX
                popoverFrame.origin.x -= difference
            }
        }

        // Vertical constraint
        if edges.contains(.vertical) {
            let minY = screen.safeArea.top + padding
            let maxY = screenSize.height - screen.safeArea.bottom - padding

            // Top edge overflow
            if popoverFrame.origin.y < minY {
                popoverFrame.origin.y = minY
            }
            // Bottom edge overflow
            if popoverFrame.maxY > maxY {
                let difference = popoverFrame.maxY - maxY
                popoverFrame.origin.y -= difference
            }
        }

        return popoverFrame
    }

    /// Calculates a point on the anchor frame based on the anchor point type
    private func calculateAnchorPoint(for anchor: PopupAnchorPoint, in frame: CGRect) -> CGPoint {
        switch anchor {
        case .topLeft:     return CGPoint(x: frame.minX, y: frame.minY)
        case .top:         return CGPoint(x: frame.midX, y: frame.minY)
        case .topRight:    return CGPoint(x: frame.maxX, y: frame.minY)
        case .left:        return CGPoint(x: frame.minX, y: frame.midY)
        case .center:      return CGPoint(x: frame.midX, y: frame.midY)
        case .right:       return CGPoint(x: frame.maxX, y: frame.midY)
        case .bottomLeft:  return CGPoint(x: frame.minX, y: frame.maxY)
        case .bottom:      return CGPoint(x: frame.midX, y: frame.maxY)
        case .bottomRight: return CGPoint(x: frame.maxX, y: frame.maxY)
        }
    }

    /// Calculates the offset within the popup based on its anchor point
    private func calculatePopupOffset(for anchor: PopupAnchorPoint, popupSize: CGSize) -> CGPoint {
        let width = popupSize.width
        let height = popupSize.height

        switch anchor {
        case .topLeft:     return CGPoint(x: 0, y: 0)
        case .top:         return CGPoint(x: width / 2, y: 0)
        case .topRight:    return CGPoint(x: width, y: 0)
        case .left:        return CGPoint(x: 0, y: height / 2)
        case .center:      return CGPoint(x: width / 2, y: height / 2)
        case .right:       return CGPoint(x: width, y: height / 2)
        case .bottomLeft:  return CGPoint(x: 0, y: height)
        case .bottom:      return CGPoint(x: width / 2, y: height)
        case .bottomRight: return CGPoint(x: width, y: height)
        }
    }
}
