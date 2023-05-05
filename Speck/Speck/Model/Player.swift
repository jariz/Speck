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

    private var core: SpeckCore?
    private var api: SpotifyAPI<SpeckAuthManager>?

    init(core: SpeckCore, api: SpotifyAPI<SpeckAuthManager>) {
        self.core = core
        self.api = api

        self.core?.init_player()
        self.startPlayerThread()
        self.scheduleTimer()
    }
    
    func seek (_ positionMS: UInt32) {
        self.core?.player_seek(positionMS)
    }
    
    private func scheduleTimer () {
        self.playStateCancellable = $playState
            .receive(on: RunLoop.main)
            .sink { state in
                self.positionTimer?.invalidate()
                
                if state == .playing {
                    self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        self.positionMS += 1000
                    }
                }
        }
    }

    private func startPlayerThread() {
        Task(priority: .background) {
            while true {
                guard let result = await self.core?.get_player_event() else {
                    continue
                }

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

    // this is for mock usage ONLY. it will instantiate a dead player.
    init(
        trackName: String, artistNames: [String], positionMS: UInt32, durationMS: UInt32,
        playState: PlayState, trackID: String
    ) {
        self.track = Track(
            name: trackName,
            album: Album(
                name: "Persona",
                images: [
                    SpotifyImage(
                        url: URL(
                            string:
                                "https://i.scdn.co/image/ab67616d00001e02370bd5f81f88ca7d7b05ec43")!
                    )
                ]),
            artists: artistNames.map { Artist(name: $0, id: $0) },
            isLocal: false,
            isExplicit: true
        )
        self.trackID = trackID
        self.durationMS = durationMS
        self.positionMS = positionMS
        
        self.playState = playState
    }

    private func setTrack(id: String) {
        if id == trackID {
            // track already loaded / being loaded, skip
            return
        }

        self.trackID = id
        self.trackInfoCancellable = self.api?.track("spotify:track:\(id)")
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
        self.core?.player_load_track(id)
    }

    public func play() {
        self.core?.player_play()
    }

    public func pause() {
        self.core?.player_pause()
    }
}
