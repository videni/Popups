//
//  PopupAnchoredStackView.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI
import UIKit

// MARK: - Anchored Popups Container

/// UIKit container with single UIHostingController for all popups
class AnchoredPopupsContainer: UIView {
    static var shared: AnchoredPopupsContainer?

    private var hostingController: UIHostingController<AnyView>?
    private var popupModel = AnchoredPopupModel()
    private var lastBoundsSize: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastBoundsSize else { return }
        lastBoundsSize = bounds.size

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.popupModel.containerSize = self.bounds.size
        }
    }

    /// Returns true only if touch is inside a popup frame
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for popup in popupModel.popups {
            if let frame = popupModel.frame(for: popup), frame.contains(point) {
                return true
            }
        }
        return false
    }

    /// Returns hit view only if touch is inside a popup frame, otherwise passes through
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for popup in popupModel.popups {
            if let frame = popupModel.frame(for: popup), frame.contains(point) {
                return hostingController?.view.hitTest(point, with: event)
            }
        }
        return nil
    }

    /// Updates popups in the container
    func updatePopups(_ popups: [AnyPopup], viewModel: VM.AnchoredStack) {
        // Create hosting controller if needed (sync, only once)
        if hostingController == nil {
            let containerView = AnchoredPopupContainerView(model: popupModel)
            let hc = UIHostingController(rootView: AnyView(containerView))
            hc.view.frame = bounds
            hc.view.backgroundColor = .clear
            hc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(hc.view)
            hostingController = hc
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Clean up sizes for removed popups
            let currentIds = Set(popups.map { $0.id.rawValue })
            let existingIds = Set(self.popupModel.popupSizes.keys)
            for id in existingIds.subtracting(currentIds) {
                self.popupModel.popupSizes.removeValue(forKey: id)
            }

            self.popupModel.popups = popups
            self.popupModel.viewModel = viewModel
        }
    }

    /// Installs container directly on Window (above rootViewController.view)
    static func install(on window: UIWindow) {
        guard shared == nil else { return }
        let container = AnchoredPopupsContainer()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false

        window.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: window.topAnchor),
            container.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor)
        ])
        container.setNeedsLayout()
        window.layoutIfNeeded()
        shared = container
    }
}

// MARK: - Popup Model (ObservableObject for SwiftUI)

@MainActor
private class AnchoredPopupModel: ObservableObject {
    @Published var popups: [AnyPopup] = []
    @Published var popupSizes: [String: CGSize] = [:]
    @Published var containerSize: CGSize = .zero
    var viewModel: VM.AnchoredStack?

    /// Calculate frame for popup (called during render, not stored)
    func frame(for popup: AnyPopup) -> CGRect? {
        let popupId = popup.id.rawValue
        guard let size = popupSizes[popupId],
              let viewModel = viewModel else { return nil }

        let position = viewModel.calculatePopupPosition(
            for: popup,
            popupSize: size,
            containerSize: containerSize
        )
        return CGRect(origin: position, size: size)
    }
}

// MARK: - SwiftUI Container View

private struct AnchoredPopupContainerView: View {
    @ObservedObject var model: AnchoredPopupModel

    var body: some View {
        // Reference containerSize to trigger re-render when it changes
        let _ = model.containerSize

        ZStack(alignment: .topLeading) {
            ForEach(model.popups, id: \.self) { popup in
                let popupId = popup.id.rawValue
                let frame = model.frame(for: popup)

                PopupContentView(popup: popup, viewModel: model.viewModel)
                    .opacity(frame != nil ? 1 : 0)
                    .sizeReader { size in
                        if model.popupSizes[popupId] != size {
                            model.popupSizes[popupId] = size
                        }
                    }
                    .offset(x: frame?.origin.x ?? 0, y: frame?.origin.y ?? 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.all)
    }
}

/// SwiftUI content for a single popup
private struct PopupContentView: View {
    let popup: AnyPopup
    var viewModel: VM.AnchoredStack?

    var body: some View {
        popup.body
            .compositingGroup()
            .fixedSize(horizontal: false, vertical: viewModel?.activePopupProperties.verticalFixedSize ?? true)
            .background(backgroundColor: popup.config.backgroundColor, overlayColor: .clear, corners: viewModel?.activePopupProperties.corners ?? [:])
            .opacity(Double(viewModel?.calculateOpacity(for: popup) ?? 1))
    }
}

// MARK: - Size Reader

private extension View {
    func sizeReader(size: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: PopupSizePreferenceKey.self, value: geometry.size)
                    .onPreferenceChange(PopupSizePreferenceKey.self) { newValue in
                        DispatchQueue.main.async {
                            size(newValue)
                        }
                    }
            }
        )
    }
}

private struct PopupSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Popup Anchored Stack View (Triggers installation and updates)

struct PopupAnchoredStackView: View {
    @ObservedObject var viewModel: VM.AnchoredStack

    var body: some View {
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
