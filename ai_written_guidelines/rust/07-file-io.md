# File I/O

## Reading files

```rust
use std::fs;
use std::io::{self, BufRead, BufReader};

// Entire file as string
let content = fs::read_to_string("config.yaml")?;

// Entire file as bytes
let data = fs::read("image.png")?;

// Line by line (large files)
let file = fs::File::open("log.txt")?;
let reader = BufReader::new(file);
for line in reader.lines() {
    let line = line?;
    println!("{}", line);
}
```

## Writing files

```rust
use std::fs;
use std::io::Write;

// Entire file
fs::write("output.txt", "hello\n")?;

// Buffered writer
let mut file = fs::File::create("output.txt")?;
let mut writer = io::BufWriter::new(&file);
writeln!(writer, "line 1")?;
writeln!(writer, "line 2")?;
writer.flush()?;

// Append
let mut file = fs::OpenOptions::new()
    .append(true)
    .create(true)
    .open("log.txt")?;
writeln!(file, "new entry")?;
```

## Path handling

```rust
use std::path::{Path, PathBuf};

// Create
let p = Path::new("data/config.yaml");
let pb = PathBuf::from("data/config.yaml");

// Properties
p.file_name();          // Some("config.yaml")
p.file_stem();          // Some("config")
p.extension();          // Some("yaml")
p.parent();             // Some(Path::new("data"))
p.is_absolute();

// Manipulation
let pb: PathBuf = ["data", "logs", "app.log"].iter().collect();
let pb = Path::new("data").join("config.yaml");
let pb = Path::new("data").join("logs").with_extension("log");
```

## Directory operations

```rust
use std::fs;

// Create
fs::create_dir("output")?;
fs::create_dir_all("output/logs/2025")?;  // recursive

// Remove
fs::remove_file("temp.txt")?;
fs::remove_dir("empty_dir")?;
fs::remove_dir_all("temp_dir")?;  // recursive

// List
for entry in fs::read_dir(".")? {
    let entry = entry?;
    println!("{}", entry.path().display());
}
```

## File info

```rust
let metadata = fs::metadata("file.txt")?;

println!("Size: {}", metadata.len());
println!("Is file: {}", metadata.is_file());
println!("Is dir: {}", metadata.is_dir());
println!("Permissions: {:o}", metadata.permissions().mode());
```

## Serialization with serde

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }
serde_yaml = "0.9"
serde_json = "1"
toml = "0.8"
```

```rust
use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize)]
struct Config {
    host: String,
    port: u16,
    debug: bool,
    features: Vec<String>,
}

// YAML
let cfg: Config = serde_yaml::from_str(&yaml_str)?;
let yaml_str = serde_yaml::to_string(&cfg)?;

// JSON
let cfg: Config = serde_json::from_str(&json_str)?;
let json_str = serde_json::to_string_pretty(&cfg)?;

// TOML
let cfg: Config = toml::from_str(&toml_str)?;
let toml_str = toml::to_string(&cfg)?;
```

## Temp files

```rust
use tempfile::{NamedTempFile, TempDir};

// Temp file
let mut tmp = NamedTempFile::new()?;
writeln!(tmp, "temporary data")?;
println!("Path: {}", tmp.path().display());
// File is deleted when tmp goes out of scope

// Persist (keep the file)
let path = tmp.persist("output.yaml")?;

// Temp dir
let tmp_dir = TempDir::new()?;
let config_path = tmp_dir.path().join("config.yaml");
fs::write(&config_path, "data")?;
// Directory is deleted when tmp_dir is dropped
```
