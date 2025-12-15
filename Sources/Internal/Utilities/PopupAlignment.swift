//
//  PopupAlignment.swift of MijickPopups
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

enum PopupAlignment {
    case top
    case center
    case bottom
    case anchored
}

// MARK: Anchor Point
public enum PopupAnchorPoint: Sendable {
    case topLeft, top, topRight
    case left, center, right
    case bottomLeft, bottom, bottomRight
}

// MARK: Initialize
extension PopupAlignment {
    init(_ config: LocalConfig.Type) { switch config.self {
        case is TopPopupConfig.Type: self = .top
        case is CenterPopupConfig.Type: self = .center
        case is BottomPopupConfig.Type: self = .bottom
        case is AnchoredPopupConfig.Type: self = .anchored
        default: fatalError()
    }}
}

// MARK: Negation
extension PopupAlignment {
    static prefix func !(lhs: Self) -> Self { switch lhs {
        case .top: .bottom
        case .center: .center
        case .bottom: .top
        case .anchored: .anchored
    }}
}

// MARK: Type Casting
extension PopupAlignment {
    func toEdge() -> Edge { switch self {
        case .top: .top
        case .center: .bottom
        case .bottom: .bottom
        case .anchored: .top
    }}
    func toAlignment() -> Alignment { switch self {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        case .anchored: .topLeading
    }}
}
