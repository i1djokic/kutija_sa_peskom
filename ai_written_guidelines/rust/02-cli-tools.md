# CLI Tools

## clap (derive API)

```toml
[dependencies]
clap = { version = "4", features = ["derive"] }
```

```rust
use clap::{Parser, Subcommand, Args};

#[derive(Parser)]
#[command(name = "myapp")]
#[command(about = "Deployment automation tool", long_about = None)]
struct Cli {
    #[arg(short, long, default_value = "localhost")]
    host: String,

    #[arg(short, long, default_value_t = 8080)]
    port: u16,

    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Deploy application
    Deploy {
        /// Environment name
        #[arg(short, long)]
        env: String,

        /// Dry run (simulate only)
        #[arg(long)]
        dry_run: bool,
    },
    /// Restart a service
    Restart {
        /// Service name
        service: String,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Some(Commands::Deploy { env, dry_run }) => {
            println!("Deploying to {} (dry-run: {})", env, dry_run);
        }
        Some(Commands::Restart { service }) => {
            println!("Restarting {}", service);
        }
        None => {
            println!("No subcommand used");
        }
    }

    Ok(())
}
```

## clap (builder API)

```rust
use clap::{Command, Arg, ArgAction};

fn main() {
    let matches = Command::new("myapp")
        .about("Deployment automation tool")
        .subcommand_required(true)
        .subcommand(
            Command::new("deploy")
                .about("Deploy application")
                .arg(Arg::new("env")
                    .short('e')
                    .long("env")
                    .help("Environment")
                    .required(true))
                .arg(Arg::new("dry-run")
                    .long("dry-run")
                    .help("Simulate only")
                    .action(ArgAction::SetTrue)),
        )
        .subcommand(
            Command::new("restart")
                .about("Restart a service")
                .arg(Arg::new("service")
                    .help("Service name")
                    .required(true)),
        )
        .get_matches();

    match matches.subcommand() {
        Some(("deploy", sub_m)) => {
            let env = sub_m.get_one::<String>("env").unwrap();
            let dry_run = sub_m.get_flag("dry-run");
            println!("Deploying to {} (dry-run: {})", env, dry_run);
        }
        Some(("restart", sub_m)) => {
            let service = sub_m.get_one::<String>("service").unwrap();
            println!("Restarting {}", service);
        }
        _ => unreachable!(),
    }
}
```

## Environment variables

```rust
use std::env;

let host = env::var("HOST").unwrap_or_else(|_| "localhost".to_string());
let port: u16 = env::var("PORT")
    .ok()
    .and_then(|p| p.parse().ok())
    .unwrap_or(8080);
let debug = env::var("DEBUG").is_ok();
```

## dotenv

```toml
[dependencies]
dotenvy = "0.15"
```

```rust
// Loads .env file at startup
dotenvy::dotenv().ok();
// Falls back to OS env vars
```

## Exit codes

```rust
use std::process;

const SUCCESS: i32 = 0;
const FAILURE: i32 = 1;
const CONFIG_ERROR: i32 = 2;
const NETWORK_ERROR: i32 = 3;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // ... 
    Ok(())
}

// Or explicit exit
process::exit(CONFIG_ERROR);
```

## Common patterns

```rust
// Logger integration
use clap::Parser;
use log::LevelFilter;

#[derive(Parser)]
struct Cli {
    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,
}

fn setup_logging(verbosity: u8) {
    let level = match verbosity {
        0 => LevelFilter::Info,
        1 => LevelFilter::Debug,
        _ => LevelFilter::Trace,
    };
    env_logger::Builder::new()
        .filter_level(level)
        .init();
}
```
