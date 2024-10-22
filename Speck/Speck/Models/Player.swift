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
    private var playStateCancellable: AnyCancellable? = nil
    private var positionTimer: Timer? = nil

    private var core: SpeckCore
    private var api: SpotifyAPI<AuthorizationCodeFlowPKCEManager>

    init(core: SpeckCore, api: SpotifyAPI<AuthorizationCodeFlowPKCEManager>) {
        self.core = core
        self.api = api

        self.core.init_player()
        self.startPlayerThread()
        self.scheduleTimer()
    }

    func seek(_ positionMS: UInt32) {
        self.core.player_seek(positionMS)
    }

    private func scheduleTimer() {
        self.playStateCancellable =
            $playState
            .receive(on: RunLoop.main)
            .sink { state in
                self.positionTimer?.invalidate()

                if state == .playing {
                    self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
                        timer in
                        self.positionMS += 1000
                    }
                }
            }
    }

    private func startPlayerThread() {
        Task(priority: .background) {
            while true {
                let result = await self.core.get_player_event()

                let type = result.event
                await MainActor.run {
                    switch type {
                    case .Stopped(_, let track_id):
                        playState = .stopped
                        getTrackInfo(id: track_id.toString())
                        positionMS = 0
                        durationMS = 0
                    case .TrackChanged(let track_id, let durationMs):
                        getTrackInfo(id: track_id.toString())
                        self.durationMS = durationMs
                    case .Loading(let play_request_id, let track_id, let position_ms):
                        getTrackInfo(id: track_id.toString())
                        positionMS = position_ms
                    case .Preloading(let track_id):
                        getTrackInfo(id: track_id.toString())
                    case .Playing(_, let track_id, let position_ms):
                        playState = .playing
                        getTrackInfo(id: track_id.toString())
                        positionMS = position_ms
                    case .Paused(_, let track_id, let position_ms):
                        playState = .paused
                        getTrackInfo(id: track_id.toString())
                        positionMS = position_ms
                    case .TimeToPreloadNextTrack(play_request_id: let play_request_id, track_id: let track_id):
                        print("NOTIMPL .TimeToPreloadNextTrack")
                    case .EndOfTrack(play_request_id: let play_request_id, track_id: let track_id):
                        print("NOTIMPL .EndOfTrack")
                    case .Unavailable(play_request_id: let play_request_id, track_id: let track_id):
                        print("NOTIMPL .Unavailable")
                    case .VolumeChanged(volume: let volume):
                        print("NOTIMPL .VolumeChanged")
                    case .PositionCorrection(_, track_id: let trackId, position_ms: let positionMS):
                        getTrackInfo(id: trackId.toString());
                        self.positionMS = positionMS
                    case .Seeked(_, track_id: let trackId, position_ms: let positionMS):
                        getTrackInfo(id: trackId.toString())
                        self.positionMS = positionMS
                    case .SessionConnected(connection_id: let connection_id, user_name: let user_name):
                        print("NOTIMPL .SessionConnected")
                    case .SessionDisconnected(connection_id: let connection_id, user_name: let user_name):
                        print("NOTIMPL .SessionDisconnected")
                    case .SessionClientChanged(client_id: let client_id, client_name: let client_name, client_brand_name: let client_brand_name, client_model_name: let client_model_name):
                        print("NOTIMPL .SessionClientChanged")
                    case .ShuffleChanged(shuffle: let shuffle):
                        print("NOTIMPL .ShuffleChanged")
                    case .RepeatChanged(enable_repeat: let enable_repeat):
                        print("NOTIMPL RepeatChanged")
                    case .AutoPlayChanged(auto_play: let auto_play):
                        print("NOTIMPL AutoPlayChanged")
                    case .FilterExplicitContentChanged(filter: let filter):
                        print("NOTIMPL .FilterExplicitContentChanged")
                    case .PlayRequestIdChanged(play_request_id: let play_request_id):
                        print("NOTIMPL .PlayRequestIdChanged")
                    }
                }

                print(playState)
            }
        }
    }

    private func getTrackInfo(id: String) {
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
