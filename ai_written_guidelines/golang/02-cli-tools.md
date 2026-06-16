# CLI Tools

## os.Args

```go
import "os"

func main() {
    if len(os.Args) < 2 {
        fmt.Println("Usage: myapp <command>")
        os.Exit(1)
    }
    cmd := os.Args[1]
    args := os.Args[2:]
    fmt.Println("Command:", cmd, "Args:", args)
}
```

## flag (stdlib)

```go
import "flag"

func main() {
    var (
        host    = flag.String("host", "localhost", "Host address")
        port    = flag.Int("port", 8080, "Port number")
        verbose = flag.Bool("verbose", false, "Verbose output")
        timeout = flag.Duration("timeout", 30*time.Second, "Timeout")
    )
    flag.Parse()

    fmt.Printf("Connecting to %s:%d (timeout: %v)\n",
        *host, *port, *timeout)
}
```

### Subcommands with flag

```go
deployCmd := flag.NewFlagSet("deploy", flag.ExitOnError)
deployEnv := deployCmd.String("env", "development", "Environment")

restartCmd := flag.NewFlagSet("restart", flag.ExitOnError)
restartSvc := restartCmd.String("service", "", "Service name")

if len(os.Args) < 2 {
    fmt.Println("expected subcommand: deploy|restart")
    os.Exit(1)
}

switch os.Args[1] {
case "deploy":
    deployCmd.Parse(os.Args[2:])
    fmt.Println("Deploying to", *deployEnv)
case "restart":
    restartCmd.Parse(os.Args[2:])
    fmt.Println("Restarting", *restartSvc)
}
```

## Cobra (most popular)

```bash
go get github.com/spf13/cobra
```

```go
package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
    Use:   "myapp",
    Short: "Automation tool",
    Long:  "A CLI tool for deployment automation",
}

var deployCmd = &cobra.Command{
    Use:   "deploy [target]",
    Short: "Deploy application",
    Args:  cobra.ExactArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        env, _ := cmd.Flags().GetString("env")
        dryRun, _ := cmd.Flags().GetBool("dry-run")
        fmt.Printf("Deploying %s to %s (dry-run: %v)\n", args[0], env, dryRun)
    },
}

var restartCmd = &cobra.Command{
    Use:   "restart [service]",
    Short: "Restart a service",
    Args:  cobra.ExactArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("Restarting", args[0])
    },
}

func init() {
    deployCmd.Flags().StringP("env", "e", "development", "Environment")
    deployCmd.Flags().Bool("dry-run", false, "Simulate only")
    deployCmd.Flags().CountP("verbose", "v", "Verbose output")

    rootCmd.AddCommand(deployCmd)
    rootCmd.AddCommand(restartCmd)
}

func Execute() {
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}
```

```go
// main.go
package main

import "myapp/cmd"

func main() {
    cmd.Execute()
}
```

## Viper (config + env)

```go
import "github.com/spf13/viper"

func initConfig() {
    viper.SetConfigName("config")     // config.yaml
    viper.SetConfigType("yaml")
    viper.AddConfigPath(".")
    viper.AddConfigPath("$HOME/.myapp")
    viper.AutomaticEnv()               // read env vars
    viper.SetEnvPrefix("MYAPP")

    // Defaults
    viper.SetDefault("port", 8080)
    viper.SetDefault("host", "localhost")

    if err := viper.ReadInConfig(); err != nil {
        // config file is optional
    }
}

// Usage
port := viper.GetInt("port")
host := viper.GetString("host")
debug := viper.GetBool("debug")
```

## Environment variables

```go
import "os"

host := os.Getenv("HOST")
port, _ := strconv.Atoi(os.Getenv("PORT"))
debug := os.Getenv("DEBUG") == "1"

// Default
host := os.Getenv("HOST")
if host == "" {
    host = "localhost"
}
```

## Common CLI patterns

```go
// Exit codes
const (
    ExitSuccess = 0
    ExitError   = 1
    ExitConfig  = 2
)

// Subcommand structure
// myapp/
//   cmd/
//     root.go
//     deploy.go
//     restart.go
//     version.go
//   main.go
```

## Makefile integration

```makefile
build:
	go build -o bin/myapp .
```
