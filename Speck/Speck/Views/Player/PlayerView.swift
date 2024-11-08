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
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }
        .background(
            EffectsView(
                material: NSVisualEffectView.Material.popover,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
        )
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            if player.durationMS > 0 {
                Slider(value: positionMS, in: 0...Double(player.durationMS))
                    .frame(maxWidth: .infinity)
                    .offset(y: -12)
                    
            }
        }

    }
}
 
