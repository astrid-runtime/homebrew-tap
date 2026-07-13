# Homebrew Tap for Astrid

Microkernel for AI agents where agents write their own harness.

## Install

```bash
brew tap astrid-runtime/tap
brew install astrid
```

## Update

```bash
brew update
brew upgrade astrid
```

## What gets installed

| Binary | Purpose |
|--------|---------|
| `astrid` | CLI frontend — TUI, headless mode, capsule management |
| `astrid-daemon` | Background kernel process — IPC, VFS, sandbox, audit |
| `astrid-build` | Capsule compiler — builds Rust, OpenClaw, and MCP capsules |

## Getting started

```bash
astrid init          # Install the default distro and capsules
astrid               # Start an interactive session
astrid -p "hello"    # Headless single-prompt mode
```

## Links

- [Source](https://github.com/astrid-runtime/astrid)
- [Documentation](https://github.com/astrid-runtime/astrid#readme)
- [Releases](https://github.com/astrid-runtime/astrid/releases)
