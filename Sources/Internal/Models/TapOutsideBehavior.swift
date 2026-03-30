//
//  TapOutsideBehavior.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import Foundation

/// Defines behavior when tapping outside an AnchoredPopup
public enum TapOutsideBehavior {
    /// Does not dismiss, does not pass through (blocks tap)
    case none
    /// Dismisses popup, does not pass through
    case dismiss
    /// Passes through to underlying views, does not dismiss
    case passThrough
    /// Dismisses on tap; passes through when `isDragging` is true
    case dismissUnlessDragging

    /// Set to `true` when a drag operation starts, `false` when it ends.
    /// Used by `.dismissUnlessDragging` to decide hitTest behavior.
    public nonisolated(unsafe) static var isDragging: Bool = false
}
