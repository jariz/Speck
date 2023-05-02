//
//  PlayerView.swift
//  Speck
//
//  Created by Jari on 01/05/2023.
//

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var player: Player

    var body: some View {
        Group {

            if player.playState == .playing {
                Button("Pause") {
                    player.pause()
                }
            }
            if player.playState == .paused {
                Button("Play") {
                    player.play()
                }
            }

        }
        .padding(10)
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
