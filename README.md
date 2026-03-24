# Homebrew Tap for Astrid

Microkernel for AI agents where agents write their own harness.

## Install

```bash
brew tap unicity-astrid/tap
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

## Getting started

```bash
astrid init          # Install the default distro and capsules
astrid               # Start an interactive session
astrid -p "hello"    # Headless single-prompt mode
```

## Links

- [Source](https://github.com/unicity-astrid/astrid)
- [Documentation](https://github.com/unicity-astrid/astrid#readme)
- [Releases](https://github.com/unicity-astrid/astrid/releases)
