# 7 Days to Die Server - Game-Specific Information

## Game Details
- **Game**: 7 Days to Die
- **Version**: Alpha 20.7
- **Steam App ID**: 294420_alpha20.7
- **Ports**: 26900 (TCP), 26900-26903 (UDP)

## File Locations
- **Game installation**: ~/steam-app-294420_alpha20.7/
- **Convenience symlink**: ~/7dtd → ~/steam-app-294420_alpha20.7
- **Server executable**: ~/steam-app-294420_alpha20.7/7DaysToDieServer.x86_64
- **Server config**: ~/steam-app-294420_alpha20.7/serverconfig.xml
- **Server logs**: ~/steam-app-294420_alpha20.7/output_log.txt
- **Mods directory**: ~/steam-app-294420_alpha20.7/Mods/
- **Save data**: /home/sevendtd/.local/share/7DaysToDie/Saves/

## Mod Installation Guide

### Overview
This server uses manual mod installation. Mods are installed directly into the server's Mods directory.
The server must be stopped before installing or updating mods.

### Mod Installation Directory
All mods should be installed to: ~/steam-app-294420_alpha20.7/Mods/

### Pre-Installation Steps

#### 1. Stop the server
```bash
just stop 7dtd
```

### Installing Specific Mods

#### Undead Legacy Mod
**Source**: https://ul.subquake.com/download

**Installation steps**:
1. Download the Undead Legacy mod from the website
2. Extract the downloaded archive
3. Copy the UndeadLegacyStable-main folder to the 7dtd directory:
```bash
unzip UndeadLegacyStable-main.zip
mv UndeadLegacyStable-main/* ~/games/steam/7dtd
chmod +x ~/games/steam/7dtd/run_bepinex_server.sh

# append "<dllmap dll="dl" target="libdl.so.2"/>" into ~/games/steam/7dtd/7DaysToDieServer_Data/MonoBleedingEdge/etc/mono/config
```

### General Mod Installation Process

For any other mods:

1. **Stop the server**: `just stop 7dtd`
2. **Download the mod** from its source
3. **Extract** if it's an archive
4. **Copy to Mods directory**:
```bash
sudo cp -r /path/to/mod-folder ~/steam-app-294420_alpha20.7/Mods/
```
5. **Fix permissions**:
```bash
sudo chown -R jeff:users ~/steam-app-294420_alpha20.7/Mods/mod-folder-name
```
6. **Start the server**: `just start 7dtd`

### Verification

#### Check installed mods:
```bash
ls -la ~/steam-app-294420_alpha20.7/Mods/
```

#### Verify mod loading in logs:
```bash
just logs 7dtd
# or
tail -f /home/sevendtd/logs/output_log.txt
```

Look for mod loading messages in the server startup logs.

### Troubleshooting

#### Common Issues:
- **Permission errors**: Make sure all mod files are owned by `steam:game`
- **Mod conflicts**: Some mods may not be compatible with each other
- **Server won't start**: Check logs for mod-related errors
- **Missing dependencies**: Ensure required mods are installed first (e.g., UL before Compo Pack)

#### File Permissions Fix:
If you have permission issues:
```bash
sudo chown -R jeff:users ~/steam-app-294420_alpha20.7/Mods/
sudo chmod -R 755 ~/steam-app-294420_alpha20.7/Mods/
```

### Important Notes

- **Backup first**: Consider backing up your save data before installing mods
- **Mod compatibility**: Ensure mods are compatible with alpha20.7
- **Load order**: Some mods depend on others (like Compo Pack requiring Undead Legacy)
- **Server restarts**: Mod changes typically require a server restart
- **Client compatibility**: Players may need the same mods installed on their clients

### Save Data Location
Your world saves are stored in: `/home/sevendtd/.local/share/7DaysToDie/Saves/`
Consider backing this up before major mod changes.
