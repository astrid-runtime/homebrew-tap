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

The tap follows Astrid's signed `stable` channel. A scheduled updater and an
input-free manual workflow authenticate the channel pointer, reject replayed or
equivocating generations, and verify the release's signed Homebrew checksums
before changing the formula. Publishing a release by itself does not update the
tap.

## What gets installed

| Binary | Purpose |
|--------|---------|
| `astrid` | CLI frontend — TUI, headless mode, capsule management |
| `astrid-daemon` | Background kernel process — IPC, VFS, sandbox, audit |
| `astrid-build` | Capsule compiler — builds Rust, OpenClaw, and MCP capsules |
| `astrid-emit` | Event client — publishes requests and inspects runtime responses |

## Getting started

```bash
astrid init --distro @yourorg/your-distro  # Install an explicit distribution
astrid                                    # Start an interactive session
astrid -p "hello"                         # Headless single-prompt mode
```

## Links

- [Source](https://github.com/astrid-runtime/astrid)
- [Documentation](https://github.com/astrid-runtime/astrid#readme)
- [Releases](https://github.com/astrid-runtime/astrid/releases)
