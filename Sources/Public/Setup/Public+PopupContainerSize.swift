//
//  Public+PopupContainerSize.swift of MijickPopups
//
//  Created by Vidy. Exposing container size to popup content.
//
//  Copyright 2024 Mijick. All rights reserved.

import SwiftUI

// MARK: - Environment Key

private struct PopupContainerSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

public extension EnvironmentValues {
    /// The size of the popup container (window size).
    /// Available in AnchoredPopup body, updates when window resizes.
    var popupContainerSize: CGSize {
        get { self[PopupContainerSizeKey.self] }
        set { self[PopupContainerSizeKey.self] = newValue }
    }
}
