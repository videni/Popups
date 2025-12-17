//
//  Public+Present+Popup.swift of MijickPopups
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2023 Mijick. All rights reserved.


import SwiftUI
#if os(iOS)
import UIKit
#endif

public extension Popup {
    /**
     Presents the popup.

     - Parameters:
        - popupStackID: The identifier registered in one of the application windows in which the popup is to be displayed.

     - Important: The **popupStackID** must be registered prior to use. For more information see ``SwiftUICore/View/registerPopups(id:configBuilder:)``.
     - Important: The methods
     ``PopupStack/dismissLastPopup(popupStackID:)``,
     ``PopupStack/dismissPopup(_:popupStackID:)-1atvy``,
     ``PopupStack/dismissPopup(_:popupStackID:)-6l2c2``,
     ``PopupStack/dismissAllPopups(popupStackID:)``,
     ``SwiftUICore/View/dismissLastPopup(popupStackID:)``,
     ``SwiftUICore/View/dismissPopup(_:popupStackID:)-55ubm``,
     ``SwiftUICore/View/dismissPopup(_:popupStackID:)-9mkd5``,
     ``SwiftUICore/View/dismissAllPopups(popupStackID:)``
     should be called with the same **popupStackID** as the one used here.

     - Warning: To present multiple popups of the same type, set a unique identifier using the method ``Popup/setCustomID(_:)``.
     */
    @MainActor func present(popupStackID: PopupStackID = .shared) async {
        await PopupStack.fetch(id: popupStackID)?.modify(.insertPopup(.init(self)))
        makePopupWindowKey()
    }

    #if os(iOS)
    @MainActor private func makePopupWindowKey() {
        // Find popup window by class name "MijickWindow"
        for window in UIApplication.shared.windows {
            let className = String(describing: type(of: window))
            if className == "MijickWindow" {
                window.makeKey()
                return
            }
        }
    }
    #else
    @MainActor private func makePopupWindowKey() {}
    #endif
}

// MARK: Anchored Popup Present
public extension AnchoredPopup {
    /**
     Presents the anchored popup positioned relative to a tracked anchor view.

     Use this with `.trackAnchor(_:)` modifier to track the source view's frame.

     - Parameters:
        - anchorID: The ID used in `.trackAnchor(_:)` on the source view.
        - customID: Optional custom identifier for the popup (for dismiss management). Defaults to anchorID.
        - popupStackID: The identifier registered in one of the application windows.

     ## Usage
     ```swift
     // Track the button
     Button("Pen") { ... }
         .trackAnchor("pen")

     // Present popup anchored to it
     MyPopup().present(anchoredTo: "pen")

     // With custom ID for dismiss management
     MyPopup().present(anchoredTo: "pen", customID: "penPopup")
     ```
     */
    @MainActor func present(
        anchoredTo anchorID: String,
        customID: String? = nil,
        popupStackID: PopupStackID = .shared
    ) async {
        var popup = await AnyPopup(self)
        // Use customID if provided, otherwise default to anchorID
        popup = await popup.updatedID(customID ?? anchorID)
        popup = popup.updatedAnchorID(anchorID)
        await PopupStack.fetch(id: popupStackID)?.modify(.insertPopup(popup))
        makePopupWindowKey()
    }

    /**
     Presents the anchored popup positioned relative to a static anchor frame.

     Use this for dynamic scenarios where you have a computed frame (e.g., list items).

     - Parameters:
        - anchorFrame: The frame of the anchor view in global coordinates.
        - customID: Optional custom identifier for the popup (for dismiss management).
        - popupStackID: The identifier registered in one of the application windows.

     ## Usage
     ```swift
     MyPopup().present(anchoredTo: buttonFrame, customID: "menu")
     ```
     */
    @MainActor func present(
        anchoredTo anchorFrame: CGRect,
        customID: String? = nil,
        popupStackID: PopupStackID = .shared
    ) async {
        var popup = await AnyPopup(self)
        if let customID = customID {
            popup = await popup.updatedID(customID)
        }
        popup = popup.updatedAnchorFrame(anchorFrame)
        await PopupStack.fetch(id: popupStackID)?.modify(.insertPopup(popup))
        makePopupWindowKey()
    }

    #if os(iOS)
    @MainActor private func makePopupWindowKey() {
        // Find popup window by class name "MijickWindow"
        for window in UIApplication.shared.windows {
            let className = String(describing: type(of: window))
            if className == "MijickWindow" {
                window.makeKey()
                return
            }
        }
    }
    #else
    @MainActor private func makePopupWindowKey() {}
    #endif
}

// MARK: Configure Popup
public extension Popup {
    /**
     Sets the custom ID for the selected popup.

     - important: To dismiss a popup with a custom ID set, use methods ``PopupStack/dismissPopup(_:popupStackID:)-1atvy`` or ``SwiftUICore/View/dismissPopup(_:popupStackID:)-55ubm``
     - tip: Useful if you want to display several different popups of the same type.
     */
    @MainActor func setCustomID(_ id: String) async -> some Popup { await AnyPopup(self).updatedID(id) }

    /**
     Supplies an observable object to a popup's hierarchy.
     */
    @MainActor func setEnvironmentObject<T: ObservableObject>(_ object: T) async -> some Popup { await AnyPopup(self).updatedEnvironmentObject(object) }

    /**
     Dismisses the popup after a specified period of time.

     - Parameters:
        - seconds: Time in seconds after which the popup will be closed.
     */
    @MainActor func dismissAfter(_ seconds: Double) async -> some Popup { await AnyPopup(self).updatedDismissTimer(seconds) }

    /**
     Configures whether the keyboard should be dismissed when the popup is removed.

     - Parameters:
        - shouldDismiss: If true, the keyboard will be dismissed when the popup appears or hides. If false, the keyboard will remain visible.
     */
    @MainActor func dismissKeyboardOnDismissal(_ shouldDismiss: Bool) async -> some Popup { await AnyPopup(self).updatedKeyboardDismissal(shouldDismiss) }
}
