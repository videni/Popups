//
//  AnchorRegistry.swift of MijickPopups
//
//  Created by Vidy. Global anchor frame registry for anchored popups.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI

/// Global registry for anchor frames, keyed by string ID.
/// Used internally by `trackAnchor(_:)` and `present(anchoredTo:)`.
@MainActor
public enum AnchorRegistry {
    private static var frames: [String: CGRect] = [:]

    /// Register or update an anchor frame
    public static func setFrame(_ frame: CGRect, forKey key: String) {
        frames[key] = frame
    }

    /// Get anchor frame by key
    public static func frame(forKey key: String) -> CGRect {
        frames[key] ?? .zero
    }

    /// Remove anchor frame
    public static func removeFrame(forKey key: String) {
        frames.removeValue(forKey: key)
    }
}
