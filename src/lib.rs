use env_logger::Env;
use librespot::core::spotify_id::{SpotifyId, SpotifyItemType};
use librespot::metadata::lyrics::SyncType;
use librespot::metadata::{Artist, Lyrics, Metadata};
use librespot::playback::audio_backend;
use librespot::playback::config::AudioFormat;
use librespot::playback::player::{PlayerEvent, PlayerEventChannel};
use librespot::{
    core::{config::SessionConfig, session::Session},
    discovery::Credentials,
    playback::{
        config::PlayerConfig,
        mixer::{softmixer::SoftMixer, Mixer, MixerConfig},
        player::Player,
    },
};
use log::debug;
use std::sync::Arc;

#[swift_bridge::bridge]
mod ffi {
    #[swift_bridge(swift_repr = "struct")]
    struct LoginResult {
        ok: bool,
        message: String,
    }

    // This is basically a redefinition of librespot's PlayerEvent beacuse of ✨ bridge reasons ✨
    enum SpeckPlayerEvent {
        // Fired when the player is stopped (e.g. by issuing a "stop" command to the player).
        Stopped {
            play_request_id: u64,
            track_id: String,
        },
        // The player is delayed by loading a track.
        Loading {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        // The player is preloading a track.
        Preloading {
            track_id: String,
        },
        // The player is playing a track.
        // This event is issued at the start of playback of whenever the position must be communicated
        // because it is out of sync. This includes:
        // start of a track
        // un-pausing
        // after a seek
        // after a buffer-underrun
        Playing {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        // The player entered a paused state.
        Paused {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        // The player thinks it's a good idea to issue a preload command for the next track now.
        // This event is intended for use within spirc.
        TimeToPreloadNextTrack {
            play_request_id: u64,
            track_id: String,
        },
        // The player reached the end of a track.
        // This event is intended for use within spirc. Spirc will respond by issuing another command.
        EndOfTrack {
            play_request_id: u64,
            track_id: String,
        },
        // The player was unable to load the requested track.
        Unavailable {
            play_request_id: u64,
            track_id: String,
        },
        // The mixer volume was set to a new level.
        VolumeChanged {
            volume: u16,
        },
        PositionCorrection {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        Seeked {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        TrackChanged {
            // TODO richer track info
            // audio_item: Box<AudioItem>,
            track_id: String,
            duration_ms: u32,
        },
        SessionConnected {
            connection_id: String,
            user_name: String,
        },
        SessionDisconnected {
            connection_id: String,
            user_name: String,
        },
        SessionClientChanged {
            client_id: String,
            client_name: String,
            client_brand_name: String,
            client_model_name: String,
        },
        ShuffleChanged {
            shuffle: bool,
        },
        RepeatChanged {
            enable_repeat: bool,
        },
        AutoPlayChanged {
            auto_play: bool,
        },
        FilterExplicitContentChanged {
            filter: bool,
        },
        PlayRequestIdChanged {
            play_request_id: u64,
        },
    }

    #[swift_bridge(swift_repr = "struct")]
    struct PlayerEventResult {
        event: SpeckPlayerEvent,
    }
    #[swift_bridge(swift_repr = "struct")]
    struct Lyrics {
        lines: Vec<String>,

        pub provider: String,
        pub provider_display_name: String,
        pub is_synced: bool,
        // pub sync_type: SyncType,
        pub color_background: i32,
        pub color_highlight_text: i32,
        pub color_text: i32,
    }

    #[swift_bridge(swift_repr = "struct")]
    pub struct Line {
        pub start_time_ms: String,
        pub end_time_ms: String,
        pub words: String,
    }

    pub enum SyncType {
        Unsynced,
        LineSynced,
    }

    extern "Rust" {
        type SpeckCore;

        #[swift_bridge(init)]
        fn new() -> SpeckCore;

        async fn login(&mut self, access_token: String) -> LoginResult;

        async fn get_player_event(&mut self) -> PlayerEventResult;

        fn init_player(&mut self);

        fn player_load_track(&mut self, track_id: String);
        fn player_pause(&self);
        fn player_play(&self);
        fn player_seek(&self, position_ms: u32);

        async fn get_lyrics(&self, track_id: String) -> Lyrics;
    }
}

pub struct SpeckCore {
    session: Option<Session>,
    player: Option<Arc<Player>>,
    channel: Option<PlayerEventChannel>,
}

impl SpeckCore {
    fn new() -> Self {
        env_logger::Builder::from_env(
            Env::default().default_filter_or("speck=debug,librespot=debug"),
        )
        .init();

        SpeckCore {
            session: None,
            player: None,
            channel: None,
        }
    }

    fn init_player(&mut self) {
        let mixer = SoftMixer::open(MixerConfig::default());
        let player = Player::new(
            PlayerConfig::default(),
            self.session.clone().unwrap(),
            mixer.get_soft_volume(),
            move || {
                // only rodio supported for now
                let backend = audio_backend::find(Some("rodio".to_string())).unwrap();
                backend(None, AudioFormat::default())
            },
        );

        let channel = player.get_player_event_channel();
        self.player = Some(player);
        self.channel = Some(channel);
    }

    async fn get_player_event(&mut self) -> ffi::PlayerEventResult {
        let event = self.channel.as_mut().unwrap().recv().await.unwrap();
        debug!("rust-speck got event: {:?}", event);
        ffi::PlayerEventResult {
            event: match event {
                // this code was brought to you by github copilot
                PlayerEvent::Playing {
                    play_request_id,
                    track_id,
                    position_ms,
                } => ffi::SpeckPlayerEvent::Playing {
                    play_request_id,
                    position_ms,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::Paused {
                    play_request_id,
                    track_id,
                    position_ms,
                } => ffi::SpeckPlayerEvent::Paused {
                    play_request_id,
                    position_ms,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::TimeToPreloadNextTrack {
                    play_request_id,
                    track_id,
                } => ffi::SpeckPlayerEvent::TimeToPreloadNextTrack {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::EndOfTrack {
                    play_request_id,
                    track_id,
                } => ffi::SpeckPlayerEvent::EndOfTrack {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::TrackChanged { audio_item } => ffi::SpeckPlayerEvent::TrackChanged {
                    track_id: audio_item.track_id.to_base62().unwrap(),
                    duration_ms: audio_item.duration_ms,
                },
                PlayerEvent::SessionConnected {
                    connection_id,
                    user_name,
                } => ffi::SpeckPlayerEvent::SessionConnected {
                    connection_id,
                    user_name,
                },
                PlayerEvent::SessionDisconnected {
                    connection_id,
                    user_name,
                } => ffi::SpeckPlayerEvent::SessionDisconnected {
                    connection_id,
                    user_name,
                },
                PlayerEvent::VolumeChanged { volume } => {
                    ffi::SpeckPlayerEvent::VolumeChanged { volume }
                }
                PlayerEvent::RepeatChanged { repeat } => ffi::SpeckPlayerEvent::RepeatChanged {
                    enable_repeat: repeat,
                },
                PlayerEvent::ShuffleChanged { shuffle } => {
                    ffi::SpeckPlayerEvent::ShuffleChanged { shuffle }
                }
                PlayerEvent::FilterExplicitContentChanged { filter } => {
                    ffi::SpeckPlayerEvent::FilterExplicitContentChanged { filter }
                }
                PlayerEvent::AutoPlayChanged { auto_play } => {
                    ffi::SpeckPlayerEvent::AutoPlayChanged { auto_play }
                }
                PlayerEvent::Stopped {
                    play_request_id,
                    track_id,
                } => ffi::SpeckPlayerEvent::Stopped {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::Loading {
                    play_request_id,
                    track_id,
                    position_ms,
                } => ffi::SpeckPlayerEvent::Loading {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                    position_ms,
                },
                PlayerEvent::Seeked {
                    play_request_id,
                    track_id,
                    position_ms,
                } => ffi::SpeckPlayerEvent::Seeked {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                    position_ms,
                },
                PlayerEvent::PositionCorrection {
                    play_request_id,
                    track_id,
                    position_ms,
                } => ffi::SpeckPlayerEvent::PositionCorrection {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                    position_ms,
                },
                PlayerEvent::Preloading { track_id } => ffi::SpeckPlayerEvent::Preloading {
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::SessionClientChanged {
                    client_id,
                    client_name,
                    client_brand_name,
                    client_model_name,
                } => ffi::SpeckPlayerEvent::SessionClientChanged {
                    client_id,
                    client_name,
                    client_brand_name,
                    client_model_name,
                },
                PlayerEvent::Unavailable {
                    play_request_id,
                    track_id,
                } => ffi::SpeckPlayerEvent::Unavailable {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::PlayRequestIdChanged { play_request_id } => {
                    ffi::SpeckPlayerEvent::PlayRequestIdChanged { play_request_id }
                }
            },
        }
    }

    // async fn get_expanded_artist_info(&self, track_id: String) {
    //     let mut id = SpotifyId::from_base62(&track_id).unwrap();
    //     id.item_type = SpotifyItemType::Track;
    //     let artist = Artist::get(self.session.as_ref().unwrap(), &id)
    //         .await
    //         .unwrap();
    //     artist.portraits;
    // }

    async fn get_lyrics(&self, track_id: String) -> ffi::Lyrics {
        let mut id = SpotifyId::from_base62(&track_id).unwrap();
        id.item_type = SpotifyItemType::Track;
        let metadata = Lyrics::get(self.session.as_ref().unwrap(), &id)
            .await
            .unwrap();
        let lyrics = metadata.lyrics;
        return ffi::Lyrics {
            lines: lyrics.lines.iter().map(|line| line.words.clone()).collect(),
            provider: lyrics.provider,
            provider_display_name: lyrics.provider_display_name,
            is_synced: lyrics.sync_type == SyncType::LineSynced,
            color_background: metadata.colors.background,
            color_highlight_text: metadata.colors.highlight_text,
            color_text: metadata.colors.text,
        };
    }

    fn player_load_track(&mut self, track_id: String) {
        let mut id = SpotifyId::from_base62(&track_id).unwrap();
        id.item_type = SpotifyItemType::Track;
        self.player.as_mut().unwrap().load(id, true, 0);
    }

    fn player_pause(&self) {
        self.player.as_ref().unwrap().pause();
    }

    fn player_play(&self) {
        self.player.as_ref().unwrap().play();
    }

    fn player_seek(&self, position_ms: u32) {
        self.player.as_ref().unwrap().seek(position_ms);
    }

    async fn login(&mut self, access_token: String) -> ffi::LoginResult {
        let session_config = SessionConfig::default();
        // let mut cache_dir = env::temp_dir();
        // cache_dir.push("spotty-cache");
        //
        // let cache = Cache::new(Some(cache_dir), None, None, None).unwrap();
        // let cached_credentials = cache.credentials();
        // let credentials = match cached_credentials {
        //     Some(s) => s,
        //     None => Credentials::with_access_token(access_token),
        // };
        let credentials = Credentials::with_access_token(access_token);
        let session = Session::new(
            session_config,
            None, // Some(cache)
        );
        let res = session.connect(credentials, true).await;

        match res {
            Ok(_) => {
                self.session = Some(session);
                ffi::LoginResult {
                    ok: true,
                    message: "".to_string(),
                }
            }
            // Err(err) => Err(format!("{:?}", err)),
            Err(err) => ffi::LoginResult {
                ok: false,
                message: err.to_string(),
            },
        }
    }
}
