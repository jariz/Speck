use env_logger::Env;
use librespot::core::spotify_id::SpotifyId;
use librespot::playback::audio_backend;
use librespot::playback::config::AudioFormat;
use librespot::playback::player::{PlayerEvent, PlayerEventChannel};
use librespot::{
    core::{cache::Cache, config::SessionConfig, keymaster, session::Session},
    discovery::Credentials,
    playback::{
        config::PlayerConfig,
        mixer::{softmixer::SoftMixer, Mixer, MixerConfig},
        player::Player,
    },
};
use log::debug;
use std::env;

const CLIENT_ID: &str = "782ae96ea60f4cdf986a766049607005";

const SCOPES: &str = "user-read-private,\
playlist-read-private,\
playlist-read-collaborative,\
user-library-read,\
user-library-modify,\
user-top-read,\
user-read-recently-played,\
user-read-playback-state,\
playlist-modify-public,\
playlist-modify-private,\
user-modify-playback-state,\
streaming,\
playlist-modify-public";

#[swift_bridge::bridge]
mod ffi {

    #[swift_bridge::bridge(swift_repr = "struct")]
    struct LoginResult {
        ok: bool,
        message: String,
    }

    #[swift_bridge::bridge(swift_repr = "struct")]
    struct SpotifyToken {
        access_token: String,
        expires_in: u32,
    }

    // This is basically a redefinition of librespot's PlayerEvent beacuse of ✨ bridge reasons ✨
    enum SpeckPlayerEvent {
        Stopped {
            play_request_id: u64,
            track_id: String,
        },
        Started {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        Changed {
            old_track_id: String,
            new_track_id: String,
        },
        Loading {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
        },
        Preloading {
            track_id: String,
        },
        Playing {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
            duration_ms: u32,
        },
        Paused {
            play_request_id: u64,
            track_id: String,
            position_ms: u32,
            duration_ms: u32,
        },
        TimeToPreloadNextTrack {
            play_request_id: u64,
            track_id: String,
        },
        EndOfTrack {
            play_request_id: u64,
            track_id: String,
        },
        Unavailable {
            play_request_id: u64,
            track_id: String,
        },
        VolumeSet {
            volume: u16,
        },
    }

    #[swift_bridge::bridge(swift_repr = "struct")]
    struct PlayerEventResult {
        event: SpeckPlayerEvent,
    }

    extern "Rust" {
        type SpeckCore;

        #[swift_bridge(init)]
        fn new() -> SpeckCore;

        async fn login(&mut self, username: String, password: String) -> LoginResult;

        async fn get_token(&mut self) -> SpotifyToken;

        async fn get_player_event(&mut self) -> PlayerEventResult;

        fn init_player(&mut self);

        fn player_load_track(&mut self, track_id: String);
        fn player_pause(&self);
        fn player_play(&self);
    }
}

pub struct SpeckCore {
    session: Option<Session>,
    player: Option<Player>,
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

    async fn get_token(&mut self) -> ffi::SpotifyToken {
        let session = self.session.as_ref().unwrap();
        keymaster::get_token(&session, CLIENT_ID, SCOPES)
            .await
            .map(|token| ffi::SpotifyToken {
                access_token: token.access_token,
                expires_in: token.expires_in,
            })
            .unwrap() // TODO I can't use Result<> in async because of bridge reasons but come on, improve pls...
    }

    fn init_player(&mut self) {
        let mixer = SoftMixer::open(MixerConfig::default());
        let (player, mut channel) = Player::new(
            PlayerConfig::default(),
            self.session.clone().unwrap(),
            mixer.get_soft_volume(),
            move || {
                // only rodio supported for now
                let backend = audio_backend::find(Some("rodio".to_string())).unwrap();
                backend(None, AudioFormat::default())
            },
        );
        self.player = Some(player);
        self.channel = Some(channel);
    }

    async fn get_player_event(&mut self) -> ffi::PlayerEventResult {
        let event = self.channel.as_mut().unwrap().recv().await.unwrap();
        debug!("rust-speck got event: {:?}", event);
        ffi::PlayerEventResult {
            event: match event {
                // this code was brought to you by github copilot
                PlayerEvent::Started {
                    play_request_id,
                    track_id,
                    position_ms,
                } => ffi::SpeckPlayerEvent::Started {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                    position_ms,
                },
                PlayerEvent::Playing {
                    play_request_id,
                    track_id,
                    position_ms,
                    duration_ms,
                } => ffi::SpeckPlayerEvent::Playing {
                    duration_ms,
                    play_request_id,
                    position_ms,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::Paused {
                    play_request_id,
                    track_id,
                    position_ms,
                    duration_ms,
                } => ffi::SpeckPlayerEvent::Paused {
                    duration_ms,
                    play_request_id,
                    position_ms,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::Stopped {
                    play_request_id,
                    track_id,
                } => ffi::SpeckPlayerEvent::Stopped {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::Changed {
                    old_track_id,
                    new_track_id,
                } => ffi::SpeckPlayerEvent::Changed {
                    old_track_id: old_track_id.to_base62().unwrap(),
                    new_track_id: new_track_id.to_base62().unwrap(),
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
                PlayerEvent::Preloading { track_id } => ffi::SpeckPlayerEvent::Preloading {
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
                PlayerEvent::Unavailable {
                    play_request_id,
                    track_id,
                } => ffi::SpeckPlayerEvent::Unavailable {
                    play_request_id,
                    track_id: track_id.to_base62().unwrap(),
                },
                PlayerEvent::VolumeSet { volume } => ffi::SpeckPlayerEvent::VolumeSet { volume },
            },
        }
    }

    fn player_load_track(&mut self, track_id: String) {
        self.player
            .as_mut()
            .unwrap()
            .load(SpotifyId::from_base62(&track_id).unwrap(), true, 0);
    }

    fn player_pause(&self) {
        self.player.as_ref().unwrap().pause();
    }

    fn player_play(&self) {
        self.player.as_ref().unwrap().play();
    }

    async fn login(&mut self, username: String, password: String) -> ffi::LoginResult {
        let session_config = SessionConfig::default();
        let mut cache_dir = env::temp_dir();
        cache_dir.push("spotty-cache");

        let cache = Cache::new(Some(cache_dir), None, None, None).unwrap();
        let cached_credentials = cache.credentials();
        let credentials = match cached_credentials {
            Some(s) => s,
            None => Credentials::with_password(username, password),
        };
        let res = Session::connect(session_config, credentials, None, true).await;

        match res {
            Ok(res) => {
                let session = res.0; // todo nicer?
                self.session = Some(session);
                return ffi::LoginResult {
                    ok: true,
                    message: "".to_string(),
                };
            }
            // Err(err) => Err(format!("{:?}", err)),
            Err(err) => ffi::LoginResult {
                ok: false,
                message: err.to_string(),
            },
        }
    }
}
