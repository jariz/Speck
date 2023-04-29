use env_logger::Env;
use librespot::{
    core::{cache::Cache, config::SessionConfig, session::Session},
    discovery::Credentials,
};
use log::debug;
use std::env;

#[swift_bridge::bridge]
mod ffi {
    #[swift_bridge::bridge(swift_repr = "struct")]
    struct LoginResult {
        ok: bool,
        message: String,
    }

    extern "Rust" {
        type Speck;

        #[swift_bridge(init)]
        fn new() -> Speck;

        async fn login(&self, username: String, password: String) -> LoginResult;
    }
}

pub struct Speck {}

impl Speck {
    fn new() -> Self {
        env_logger::Builder::from_env(
            Env::default().default_filter_or("speck=debug,librespot=debug"),
        )
        .init();

        Speck {}
    }

    async fn login(&self, username: String, password: String) -> ffi::LoginResult {
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
            Ok(res) => ffi::LoginResult {
                ok: true,
                message: "".to_string(),
            },
            // Err(err) => Err(format!("{:?}", err)),
            Err(err) => ffi::LoginResult {
                ok: false,
                message: err.to_string(),
            },
        }
    }
}
