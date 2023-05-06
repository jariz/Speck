//
//  PlayerView.swift
//  Speck
//
//  Created by Jari on 01/05/2023.
//

import SkeletonUI
import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var player: Player

    var body: some View {
        let positionMS = Binding<Double>(
            get: {
                Double(player.positionMS)
            },
            set: {
                let newValue = UInt32($0)
                player.positionMS = newValue
                player.seek(newValue)
            }
        )

        VStack(alignment: .leading, spacing: 0) {
            if player.durationMS > 0 {
                Slider(value: positionMS, in: 0...Double(player.durationMS))
                    .offset(y: -12)
            }

            ZStack(alignment: .center) {
                if let track = player.track {
                    NowPlayingView(track: track)

                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                        }
                        .buttonStyle(.borderless)

                        if player.playState == .playing {
                            Button(action: {
                                player.pause()
                            }) {
                                Image(systemName: "pause.fill")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .cornerRadius(50)
                        }
                        if player.playState == .paused {
                            Button(action: {
                                player.play()
                            }) {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .cornerRadius(50)
                        }

                        Button(action: {}) {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                        }
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
        }
        .background(
            EffectsView(
                material: NSVisualEffectView.Material.sidebar,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
        )
        .frame(maxWidth: .infinity)

    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
            .environmentObject(
                Player(
                    trackName: "Atlas Corporation",
                    artistNames: ["Nathan Micay", "Eiffel 65"],
                    positionMS: 64 * 1000,
                    durationMS: 154 * 1000, playState: .playing, trackID: "123456"))
    }
}
