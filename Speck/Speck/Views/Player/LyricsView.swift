//
//  LyricsView.swift
//  Speck
//
//  Created by Jari on 07/11/2024.
//
import SwiftUI

struct LyricsView: View {
    
    @State private var showRight = false
    
    @EnvironmentObject var player: Player
    
    @State var lyrics: Lyrics?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let lines = lyrics?.lines {
                    ForEach((lines).map { $0.as_str() }) { line in
                        Text(line.toString())
                            .font(.title2)
                            .bold()
//                            .foregroundStyle(.regularMaterial)
                    }
                }
            }
            .padding(18)
            .frame(width: showRight ? 300 : 0)
        }
        .frame(maxHeight: .infinity)
        .frame(width: showRight ? 300 : 0)
        .background(
            EffectsView(
                material: NSVisualEffectView.Material.sidebar,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation {
                        showRight.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.right")
                }
            }
        }
        .onChange(of: player.track) { oldValue, newValue in
            if let track = newValue {
                Task {
                    let lyrics = await Lyrics.from(track)
                    withAnimation {
                        self.lyrics = lyrics
                    }
                    
                    debugPrint(lyrics)
                }
            }
        }
        
        
    }
}
