use std::env;
use log::{debug};
use env_logger::Env;
use librespot::{core::{config::SessionConfig, cache::Cache, session::Session}, discovery::Credentials};

#[swift_bridge::bridge]
mod ffi {
    // #[swift_bridge::bridge(swift_repr = "struct")]
    // struct SpeckError {
    //     code: u8
    // }

    extern "Rust" {
        type Speck;

        #[swift_bridge(init)]
        fn new() -> Speck;

        async fn start(&self, username: String, password: String) -> String;
    }
}

pub struct Speck {}

impl Speck {
    fn new() -> Self {
        Speck {}
    }

    async fn start(&self, username: String, password: String) -> String {
        env_logger::Builder::from_env(
            Env::default().default_filter_or("speck=debug,librespot=debug"),
        )
        .init();
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
             Ok(res) => "OK".to_string(),
             Err(err) => panic!("Error: {:?}", err)
        }
         
    }
}
