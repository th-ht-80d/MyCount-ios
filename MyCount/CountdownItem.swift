//
//  CountdownItem.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import Foundation

enum CountMode: String, Codable, CaseIterable {
    case countdown
    case countup

    var title: String {
        switch self {
        case .countdown:
            return "カウントダウン"
        case .countup:
            return "カウントアップ"
        }
    }
}

struct CountdownItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var targetDate: Date
    var createdAt: Date
    var updatedAt: Date
    var imageId: String
    var customImageData: Data?
    var countMode: CountMode
}
