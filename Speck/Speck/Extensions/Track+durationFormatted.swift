//
//  Track+durationFormatted.swift
//  Speck
//
//  Created by Jari on 06/05/2023.
//

import Foundation
import SpotifyWebAPI

extension Track {
    public var durationFormatted: String {
        guard let durationMS = self.durationMS else { return "" }
        let interval = TimeInterval(durationMS / 1000)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? ""
    }
}
