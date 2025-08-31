# Game Server Management

## Overview
Game servers are managed using the justfile recipes. Each game runs as a transient systemd service
created on-demand by systemd-run. Game files are downloaded using direct steamcmd execution.

## Justfile Usage

### Basic Commands:
```bash
# Show all game services status
just status

# List available games with details
just list

# Start a game server (validates files first)
just start <game>

# Stop a game server
just stop <game>

# Restart a game server
just restart <game>

# Show recent logs for a game
just logs <game>

# Update/download game files (with progress display)
just update <game>          # Download if needed
just update <game> --force  # Force re-download

# Show detailed information about a game
just info <game>

# Clean/uninstall a game (stop, remove files)
just clean <game>                    # Basic cleanup
just clean <game> --user-data       # Also remove user data
just clean <game> --all             # Complete cleanup

# Show game server ports and network status
just network

# Show disk usage for game files
just disk
```

## Key Features

### Download Management:
- **Direct steamcmd execution**: Real progress, Ctrl+C support
- **JSON markers**: Rich metadata, validation, idempotent updates
- **Force updates**: `--force` flag bypasses completion checks

### File Validation:
- Game start validates files exist and download completed successfully
- JSON markers track file counts, sizes, validation status
- Clear error messages guide users to fix issues

### Network Status:
- Port status checking for each game
- Service status integration
- Game-specific port ranges

## Available Games
Run `just list` to see all configured games with their details.

## Game-Specific Documentation
Each game may have additional documentation in its own file (e.g., `7dtd-mods.md`).

## Notes
- Games run as transient systemd units (no persistent auto-start by default)
- Steam dependencies are automatically downloaded when starting a game
- Use `just enable <game>` to create persistent services that start on boot
- All game data is stored in `~/` and game-specific user directories
