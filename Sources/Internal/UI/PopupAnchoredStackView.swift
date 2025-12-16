//
//  PopupAnchoredStackView.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI
import UIKit

// MARK: - Anchored Popups Container (Added directly to Window, bypassing SwiftUI hierarchy)

/// UIKit container managing multiple popup UIHostingControllers
/// Added directly to Window, not through SwiftUI view hierarchy
class AnchoredPopupsContainer: UIView {
    static var shared: AnchoredPopupsContainer?

    private var popupViews: [String: UIView] = [:]
    private var hostingControllers: [String: UIHostingController<AnyView>] = [:]

    /// Returns false when touch is outside popup, allowing events to pass through to underlying views
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            let convertedPoint = convert(point, to: subview)
            if subview.point(inside: convertedPoint, with: event) {
                return true
            }
        }
        return false
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews.reversed() {
            let convertedPoint = convert(point, to: subview)
            if let hitView = subview.hitTest(convertedPoint, with: event) {
                return hitView
            }
        }
        return nil
    }

    /// Updates popups in the container
    func updatePopups(_ popups: [AnyPopup], viewModel: VM.AnchoredStack) {
        let currentIds = Set(popups.map { $0.id.rawValue })
        let existingIds = Set(popupViews.keys)

        // Remove popups that no longer exist
        for id in existingIds.subtracting(currentIds) {
            popupViews[id]?.removeFromSuperview()
            popupViews[id] = nil
            hostingControllers[id] = nil
        }

        // Add or update popups
        for popup in popups {
            let id = popup.id.rawValue

            if let existingView = popupViews[id] {
                let actualSize = existingView.frame.size
                let position = viewModel.calculatePopupPosition(for: popup, popupSize: actualSize)
                var newFrame = existingView.frame
                newFrame.origin = CGPoint(x: position.x, y: position.y)
                existingView.frame = newFrame
            } else {
                let (hostingController, popupView) = createPopupView(for: popup, viewModel: viewModel)
                popupView.sizeToFit()
                let actualSize = popupView.frame.size
                let position = viewModel.calculatePopupPosition(for: popup, popupSize: actualSize)
                var frame = popupView.frame
                frame.origin = CGPoint(x: position.x, y: position.y)
                popupView.frame = frame
                addSubview(popupView)
                popupViews[id] = popupView
                hostingControllers[id] = hostingController
            }
        }
    }

    private func createPopupView(for popup: AnyPopup, viewModel: VM.AnchoredStack) -> (UIHostingController<AnyView>, UIView) {
        let content = AnyView(PopupContentView(popup: popup, viewModel: viewModel))
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        return (hostingController, hostingController.view)
    }

    /// Installs container directly on Window (above rootViewController.view)
    static func install(on window: UIWindow) {
        guard shared == nil else { return }
        let container = AnchoredPopupsContainer()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false

        // Add directly to window, above rootViewController.view
        window.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: window.topAnchor),
            container.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor)
        ])
        // Force layout to apply constraints
        container.setNeedsLayout()
        window.layoutIfNeeded()
        shared = container
    }
}

/// SwiftUI content for a single popup
private struct PopupContentView: View {
    let popup: AnyPopup
    @ObservedObject var viewModel: VM.AnchoredStack

    var body: some View {
        popup.body
            .compositingGroup()
            .fixedSize(horizontal: false, vertical: viewModel.activePopupProperties.verticalFixedSize)
            .background(backgroundColor: popup.config.backgroundColor, overlayColor: .clear, corners: viewModel.activePopupProperties.corners)
            .opacity(viewModel.calculateOpacity(for: popup))
    }
}

// MARK: - Popup Anchored Stack View (Triggers installation and updates)

struct PopupAnchoredStackView: View {
    @ObservedObject var viewModel: VM.AnchoredStack

    var body: some View {
        // InstallerView is only used to get window reference and install container
        // AnchoredPopupsContainer is added directly to Window, not in SwiftUI hierarchy
        AnchoredStackInstaller(viewModel: viewModel)
            .frame(width: 1, height: 1)
    }
}

/// Used to get the current view's window and install the container
private struct AnchoredStackInstaller: UIViewRepresentable {
    @ObservedObject var viewModel: VM.AnchoredStack

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.viewModel = viewModel
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        uiView.viewModel = viewModel
        uiView.updateIfNeeded()
    }
}

private class InstallerView: UIView {
    var viewModel: VM.AnchoredStack?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installContainerIfNeeded()
        updatePopups()
    }

    func updateIfNeeded() {
        installContainerIfNeeded()
        updatePopups()
    }

    private func installContainerIfNeeded() {
        guard AnchoredPopupsContainer.shared == nil, let window = window else { return }
        AnchoredPopupsContainer.install(on: window)
    }

    private func updatePopups() {
        if let viewModel = viewModel {
            AnchoredPopupsContainer.shared?.updatePopups(viewModel.popups, viewModel: viewModel)
        }
    }
}

