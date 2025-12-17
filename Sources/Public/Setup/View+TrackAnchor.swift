//
//  View+TrackAnchor.swift of MijickPopups
//
//  Created by Vidy. Track view frames for anchored popups.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI

public extension View {
    /// Tracks this view's global frame in the anchor registry.
    /// Use this with `present(anchoredTo:)` to anchor popups to this view.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Show Popup") { ... }
    ///     .trackAnchor("myButton")
    ///
    /// // Then present popup anchored to this button
    /// MyPopup().present(anchoredTo: "myButton")
    /// ```
    ///
    /// - Parameter id: A unique identifier for this anchor. Use the same ID in `present(anchoredTo:)`.
    /// - Returns: A view that tracks its frame in the global anchor registry.
    func trackAnchor(_ id: String) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        AnchorRegistry.setFrame(geo.frame(in: .global), forKey: id)
                    }
                    .onChange(of: geo.frame(in: .global)) { newFrame in
                        AnchorRegistry.setFrame(newFrame, forKey: id)
                    }
                    .onDisappear {
                        AnchorRegistry.removeFrame(forKey: id)
                    }
            }
        )
    }
}
