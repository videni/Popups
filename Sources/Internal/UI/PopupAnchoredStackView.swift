//
//  PopupAnchoredStackView.swift of MijickPopups
//
//  Created by Vidy. Extending MijickPopups with anchored popup support.
//
//  Copyright 2024 Mijick. All rights reserved.


import SwiftUI

struct PopupAnchoredStackView: View {
    @ObservedObject var viewModel: VM.AnchoredStack


    var body: some View { if viewModel.screen.height > 0 {
        ZStack(alignment: .topLeading, content: createPopupStack)
            .id(viewModel.popups.isEmpty)
            .frame(maxWidth: .infinity, maxHeight: viewModel.screen.height)
    }}
}
private extension PopupAnchoredStackView {
    func createPopupStack() -> some View {
        ForEach(viewModel.popups, id: \.self, content: createPopup)
    }
}
private extension PopupAnchoredStackView {
    func createPopup(_ popup: AnyPopup) -> some View {
        PopupAnchoredContentView(popup: popup, viewModel: viewModel)
            .opacity(viewModel.calculateOpacity(for: popup))
    }
}

// MARK: - Anchored Content View
/// A wrapper view that measures popup size and positions it correctly
private struct PopupAnchoredContentView: View {
    let popup: AnyPopup
    @ObservedObject var viewModel: VM.AnchoredStack
    @State private var popupSize: CGSize = .zero

    var body: some View {
        let position = viewModel.calculatePopupPosition(for: popup, popupSize: popupSize)

        popupContent
            .background(GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                if popupSize != newSize {
                    popupSize = newSize
                }
            }
            .offset(x: position.x, y: position.y)
            .transition(transition)
    }

    @ViewBuilder
    private var popupContent: some View {
        popup.body
            .compositingGroup()
            .fixedSize(horizontal: false, vertical: viewModel.activePopupProperties.verticalFixedSize)
            .onHeightChange { await viewModel.updatePopupHeight($0, popup) }
            .background(backgroundColor: popup.config.backgroundColor, overlayColor: .clear, corners: viewModel.activePopupProperties.corners)
            .focusSection_tvOS()
    }

    private var transition: AnyTransition {
        .scale(scale: 0.9, anchor: transitionAnchor).combined(with: .opacity)
    }

    private var transitionAnchor: UnitPoint {
        switch popup.config.popupAnchor {
        case .topLeft: return .topLeading
        case .top: return .top
        case .topRight: return .topTrailing
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .bottomLeft: return .bottomLeading
        case .bottom: return .bottom
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - Size Preference Key
private struct SizePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
