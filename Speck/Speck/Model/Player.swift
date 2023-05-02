//
//  Player.swift
//  Speck
//
//  Created by Jari on 01/05/2023.
//

import Combine
import Foundation
import SpotifyWebAPI

enum PlayState {
    case playing
    case stopped
    case paused

    // todo buffering? (see PlayerEvent::Loading)
}

final class Player: ObservableObject {
    @Published var track: Track?
    private var trackID: String?

    @Published var playState: PlayState = .stopped

    @Published var positionMS: UInt32 = 0
    @Published var durationMS: UInt32 = 0

    private var trackInfoCancellable: AnyCancellable? = nil

    private var core: SpeckCore
    private var api: SpotifyAPI<SpeckAuthManager>

    init(core: SpeckCore, api: SpotifyAPI<SpeckAuthManager>) {
        self.core = core
        self.api = api

        self.core.init_player()
        Task(priority: .background) {
            while true {
                let result = await self.core.get_player_event()
                let type = result.event
                await MainActor.run {
                    switch type {
                    case .Stopped(_, let track_id):
                        playState = .stopped
                        setTrack(id: track_id.toString())
                        positionMS = 0
                        durationMS = 0
                    case .Started(let play_request_id, let track_id, let position_ms):
                        setTrack(id: track_id.toString())
                        positionMS = position_ms
                    case .Changed(let old_track_id, let new_track_id):
                        setTrack(id: new_track_id.toString())
                    case .Loading(let play_request_id, let track_id, let position_ms):
                        setTrack(id: track_id.toString())
                        positionMS = position_ms
                    case .Preloading(let track_id):
                        setTrack(id: track_id.toString())
                    case .Playing(
                        _, let track_id, let position_ms, let duration_ms):
                        playState = .playing
                        setTrack(id: track_id.toString())
                        positionMS = position_ms
                        durationMS = duration_ms
                    case .Paused(_, let track_id, let position_ms, let duration_ms):
                        playState = .paused
                        setTrack(id: track_id.toString())
                        positionMS = position_ms
                        durationMS = duration_ms
                    case .TimeToPreloadNextTrack(let play_request_id, let track_id):
                        print("NOTIMPL .TimeToPreloadNextTrack")
                    case .EndOfTrack(let play_request_id, let track_id):
                        print("NOTIMPL .EndOfTrack")
                    case .Unavailable(let play_request_id, let track_id):
                        print("NOTIMPL .Unavailable")
                    case .VolumeSet(let volume):
                        print("NOTIMPL .VolumeSet")
                    }
                }

                print(playState)
            }
        }
    }

    private func setTrack(id: String) {
        if id == trackID {
            // track already loaded / being loaded, skip
            return
        }

        self.trackID = id
        self.trackInfoCancellable = self.api.track("spotify:track:\(id)")
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    print(completion)
                },
                receiveValue: { track in
                    self.track = track
                })
    }

    public func loadTrack(id: String) {
        self.core.player_load_track(id)
    }

    public func play() {
        self.core.player_play()
    }

    public func pause() {
        self.core.player_pause()
    }
}
