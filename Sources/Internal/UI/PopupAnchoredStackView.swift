//
//  PopupAnchoredStackView.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI

// MARK: - Anchored Popup Frame Tracker

/// Lightweight shared frame tracker for SceneDelegate hit testing.
/// The SwiftUI view updates frames; MijickWindow reads them for touch routing.
@MainActor
class AnchoredPopupFrameTracker {
    static let shared = AnchoredPopupFrameTracker()
    private init() {}

    private(set) var frames: [String: CGRect] = [:]
    private(set) var popups: [AnyPopup] = []

    func update(popups: [AnyPopup], frames: [String: CGRect]) {
        self.popups = popups
        self.frames = frames
    }

    func frame(for popup: AnyPopup) -> CGRect? {
        frames[popup.id.rawValue]
    }

    func clear() {
        popups = []
        frames = [:]
    }
}

// MARK: - Popup Anchored Stack View (Pure SwiftUI)

struct PopupAnchoredStackView: View {
    @ObservedObject var viewModel: VM.AnchoredStack

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(viewModel.popups, id: \.self) { popup in
                createPopupView(popup)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .onChange(of: viewModel.popups) { newPopups in
            cleanUpRemovedPopups(newPopups)
            syncFrameTracker()
        }
    }

    // MARK: - Private Methods

    private func createPopupView(_ popup: AnyPopup) -> some View {
        let popupId = popup.id.rawValue
        let popupFrame = frame(for: popup)
        let hasFrame = popupFrame != nil

        return popup.body
            .environment(\.popupContainerSize, containerSize)
            .compositingGroup()
            .fixedSize(horizontal: false, vertical: viewModel.activePopupProperties.verticalFixedSize)
            .opacity(Double(viewModel.calculateOpacity(for: popup)))
            .sizeReader { size in
                guard viewModel.popupSizes[popupId] != size else { return }
                viewModel.popupSizes[popupId] = size
                syncFrameTracker()
            }
            .offset(x: popupFrame?.origin.x ?? 0, y: popupFrame?.origin.y ?? 0)
            .opacity(hasFrame ? 1 : 0)
    }

    private func frame(for popup: AnyPopup) -> CGRect? {
        guard let size = viewModel.popupSizes[popup.id.rawValue] else { return nil }
        let position = viewModel.calculatePopupPosition(
            for: popup,
            popupSize: size,
            containerSize: containerSize
        )
        return CGRect(origin: position, size: size)
    }

    private var containerSize: CGSize {
        let screen = viewModel.screen
        let width = screen.width > 0 ? screen.width : UIScreen.main.bounds.width
        let height = screen.height > 0 ? screen.height : UIScreen.main.bounds.height
        return CGSize(width: width, height: height)
    }

    private func cleanUpRemovedPopups(_ newPopups: [AnyPopup]) {
        let currentIds = Set(newPopups.map { $0.id.rawValue })
        for key in viewModel.popupSizes.keys where !currentIds.contains(key) {
            viewModel.popupSizes.removeValue(forKey: key)
        }
    }

    private func syncFrameTracker() {
        var computedFrames: [String: CGRect] = [:]
        for popup in viewModel.popups {
            if let f = frame(for: popup) {
                computedFrames[popup.id.rawValue] = f
            }
        }
        AnchoredPopupFrameTracker.shared.update(popups: viewModel.popups, frames: computedFrames)
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
