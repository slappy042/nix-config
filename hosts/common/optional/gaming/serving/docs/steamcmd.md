# SteamCMD Direct Execution

## Overview
Game files are downloaded using direct steamcmd execution via the justfile.
This provides better user control and real-time progress feedback.

## Usage

### Download/Update a Game:
```bash
just update <game>          # Download/update game files
just update <game> --force  # Force re-download even if files exist
```

### Check download status:
```bash
just info <game>            # Shows download status with JSON marker info
```

## File Locations

### Downloaded Apps:
Apps are downloaded to `~/games/steam/<game-short-name>/`

### Completion Tracking:
Each successful download creates a JSON completion marker:
- **Marker file**: `~/games/steam/<game-short-name>/.steamcmd-completed`
- **Content**: JSON with timestamp, app info, file counts, validation status
- **Purpose**: Track download status, enable idempotent updates, store metadata

### Example JSON Marker:
```json
{
  "timestamp": "2025-08-30T14:30:15-07:00",
  "steam_app": "294420_alpha20.7",
  "app_id": "294420",
  "beta_branch": "alpha20.7",
  "download_status": "success",
  "game_dir": "/home/jeff/games/steam/7dtd",
  "file_count": 1247,
  "total_size": "2.3GB",
  "validation_status": "passed",
  "last_updated": "2025-08-30T14:30:15-07:00"
}
```

## Benefits

### Direct Execution Advantages:
- **User Control**: Ctrl+C works to interrupt downloads
- **Real Progress**: Actual steamcmd output visible to user
- **Simpler Architecture**: No systemd service complexity
- **Better Debugging**: Direct execution easier to troubleshoot

### JSON Marker Advantages:
- **Rich Metadata**: File counts, sizes, timestamps, validation status
- **Query with jq**: Easy to parse and validate programmatically
- **Idempotent Updates**: Skip downloads when files are current
- **Force Refresh**: Delete marker to force re-download

## Common Steam App IDs

| Game | App ID | Branch | Full Service Name |
|------|---------|---------|-------------------|
| 7 Days to Die | 294420 | alpha20.7 | steam@294420_alpha20.7 |
| Valheim | 896660 | (none) | steam@896660 |
| Satisfactory | 1690800 | experimental | steam@1690800_experimental |

## Adding New Games

To add a new Steam app:

1. **Find the App ID**: Look up the dedicated server App ID on Steam
2. **Determine branch**: Check if you need a specific branch (alpha, beta, etc.)
3. **Start the service**: `sudo systemctl start steam@{APPID}_{BRANCH}`

### Beta/Branch Format:
```bash
# No beta: steam@APPID
sudo systemctl start steam@896660

# With beta branch: steam@APPID_BRANCH
sudo systemctl start steam@294420_alpha20.7

# With beta + password: steam@APPID_BRANCH_PASSWORD
sudo systemctl start steam@123456_experimental_secretpassword
```

## Troubleshooting

### Common Issues:

#### Download Fails:
```bash
# Check logs for errors
sudo journalctl -u steam@294420_alpha20.7

# Try restarting steam service
sudo systemctl restart steam@294420_alpha20.7
```

    #### Permission Issues:
    ```bash
    # Fix ownership (should be jeff:users)
    sudo chown -R jeff:users ~/steam-app-*
    ```#### Disk Space:
```bash
# Check available space
df -h /home

# Clean old downloads if needed
sudo rm -rf ~/steam-app-old-version/
```

#### Network Issues:
- Steam downloads require internet access
- Downloads can be large (1-5GB per game)
- Consider running during off-peak hours

## Service Dependencies

Game servers typically depend on the steam@ service:
```
gameserver.service
    ├── wants: steam@APPID.service
    └── after: steam@APPID.service
```

This ensures the game files are downloaded before the game server starts.

## Maintenance

### Update All Games:
```bash
# Stop all game servers first
sudo systemctl stop sevendtd
sudo systemctl stop valheim

# Update game files
sudo systemctl start steam@294420_alpha20.7
sudo systemctl start steam@896660

# Restart game servers
sudo systemctl start sevendtd
sudo systemctl start valheim
```

### Check App Versions:
```bash
# Look for version files in the app directory
find ~/steam-app-* -name "version*" -o -name "*.txt" | head -10
```

## File Permissions

All Steam app files are owned by `jeff:users`:
- User: `jeff` (runs the download service)
- Group: `jeff` (user's default group)
- Permissions: 775 for directories, 664 for files

This allows jeff to manage game files.
