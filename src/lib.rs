use env_logger::Env;
use librespot::{
    core::{cache::Cache, config::SessionConfig, keymaster, session::Session},
    discovery::Credentials,
};
use log::debug;
use std::env;

use librespot::core::keymaster::Token;

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

    extern "Rust" {
        type Speck;

        #[swift_bridge(init)]
        fn new() -> Speck;

        async fn login(&mut self, username: String, password: String) -> LoginResult;

        async fn get_token(&mut self) -> SpotifyToken;
    }
}

pub struct Speck {
    session: Option<Session>,
}

impl Speck {
    fn new() -> Self {
        env_logger::Builder::from_env(
            Env::default().default_filter_or("speck=debug,librespot=debug"),
        )
        .init();

        Speck { session: None }
    }

    async fn get_token(&mut self) -> ffi::SpotifyToken {
        let session = self.session.as_ref().unwrap();
        keymaster::get_token(&session, CLIENT_ID, SCOPES)
            .await
            .map(|token| ffi::SpotifyToken {
                access_token: token.access_token,
                expires_in: token.expires_in,
            })
            .unwrap()
    }

    async fn login(&mut self, username: String, password: String) -> ffi::LoginResult {
        debug!("usr {}, pw {}", username, password);

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
                let token = self.get_token().await;
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
