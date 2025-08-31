# PAM SSH Agent Setup

This directory contains configurations for setting up PAM (Pluggable Authentication Modules) to automatically unlock SSH keys and avoid typing passphrases repeatedly.

## Options Available

### 1. KWallet Integration (Recommended for KDE users)
**File: `pam-kwallet.nix`**

Best for KDE Plasma desktop environments. Automatically unlocks KWallet on login, which can then manage SSH keys.

**Features:**
- Integrates with KDE ecosystem
- GUI management via KWallet Manager
- Automatic unlock on login
- Works with existing KDE workflow

**To use:** Add to your host configuration:
```nix
"hosts/common/optional/pam-kwallet.nix"
```

### 2. GNOME Keyring Integration
**File: `pam-gnome-keyring.nix`**

Good for users who want cross-desktop compatibility or use applications that expect gnome-keyring.

**Features:**
- Works well with VS Code and other applications
- Cross-desktop environment compatibility
- GUI management via Seahorse
- Automatic unlock on login

**To use:** Add to your host configuration:
```nix
"hosts/common/optional/pam-gnome-keyring.nix"
```

### 3. Keychain Solutions ⭐ **MOST PORTABLE**

**🌍 Universal compatibility** - works with ANY desktop environment or no DE at all.

**Environments tested:**
- ✅ KDE Plasma, GNOME, XFCE
- ✅ Hyprland, Sway, i3, dwm
- ✅ VT Console (TTY)
- ✅ SSH sessions
- ✅ Docker containers
- ✅ Headless servers

#### **Option 3A: Full PAM Integration** ⚡ **RECOMMENDED**
**File: `pam-ssh-keychain.nix`**

Complete PAM integration that automatically unlocks SSH keys at login using your login password.

**Features:**
- True single sign-on (if login password = SSH passphrase)
- Uses familiar GUI password dialogs (ksshaskpass)
- PAM hooks for immediate unlock after login
- Works with both GUI and TTY logins
- 8-hour key caching

**How it works:**
1. You log in with your password
2. PAM automatically runs keychain
3. If login password = SSH passphrase → GUI dialog appears (just click OK!)
4. SSH keys unlocked for 8 hours across all terminals

#### **Option 3B: Simple Systemd Service**
**File: `pam-ssh-keychain-simple.nix`**

Lighter approach using systemd user service instead of direct PAM hooks.

**Features:**
- Systemd user service runs after login
- More reliable and easier to debug
- Still uses GUI password prompts
- Fallback for complex PAM environments

**How it works:**
1. You log in
2. Systemd user service starts keychain
3. First SSH operation prompts for passphrase (GUI dialog)
4. Subsequent operations are automatic

**To use either keychain option:** Add to your host configuration:
```nix
"hosts/common/optional/pam-ssh-keychain.nix"        # Full PAM integration
# OR
"hosts/common/optional/pam-ssh-keychain-simple.nix" # Systemd service
```

**Alternative:** User-level configuration (add to your home.nix):
```nix
"home/jeff/common/optional/keychain.nix"
```

## How It Works

### **Keychain PAM Integration (Recommended)**

1. **Login**: You log in with your user password (GUI or TTY)
2. **PAM Trigger**: PAM automatically runs keychain initialization script
3. **Key Detection**: Script finds your SSH keys (id_camelot, id_yubikey, etc.)
4. **Smart Unlock**:
   - If keys already unlocked → Nothing happens (instant)
   - If keys need unlock → Uses SSH_ASKPASS (GUI dialog in KDE/GNOME, terminal prompt in TTY)
   - If login password = SSH passphrase → Just click "OK" in the dialog!
5. **Persistence**: Keys remain unlocked for 8 hours across all terminals and SSH sessions

### **Traditional Solutions (KWallet/GNOME Keyring)**

1. **PAM Integration**: When you log in, PAM modules automatically unlock your chosen keyring/keychain
2. **SSH Agent**: Your SSH agent (already configured in `hosts/common/core/ssh.nix`) uses the unlocked keys
3. **Automatic Key Loading**: With `addKeysToAgent = "yes"` in your SSH config, keys are automatically loaded when first used

## Why Keychain + PAM is Superior

- **🔄 Environment Independent**: Switch from KDE → Hyprland → TTY → SSH - same experience
- **🔐 Secure**: Only unlocks after successful authentication
- **⚡ Efficient**: One unlock per 8-hour session, reused across all terminals
- **🎨 User Friendly**: Uses your desktop's native password dialogs when available
- **🛠️ Debuggable**: Simple shell scripts, easy to troubleshoot

## Current SSH Configuration

Your SSH configuration already includes the necessary settings:
- `programs.ssh.startAgent = true` (system-level)
- `services.ssh-agent.enable = true` (user-level)
- `addKeysToAgent = "yes"` (automatically adds keys to agent when used)

## Next Steps

### **Recommended Approach: Keychain + PAM**

1. **Choose your keychain approach:**
   ```nix
   # Full PAM integration (recommended for seamless experience)
   "hosts/common/optional/pam-ssh-keychain.nix"

   # OR simpler systemd service approach (easier to debug)
   "hosts/common/optional/pam-ssh-keychain-simple.nix"
   ```

2. **Add to your host configuration** (e.g., `hosts/nixos/z13flow/default.nix`):
   ```nix
   imports = [
     # ...existing imports...
     "hosts/common/optional/pam-ssh-keychain.nix"  # Add this line
   ];
   ```

3. **Rebuild your system:**
   ```bash
   sudo nixos-rebuild switch
   ```

4. **Test the setup:**
   - **GUI Login**: Reboot and log in normally
   - **First SSH operation**: You might see a password dialog (click OK if password matches)
   - **Subsequent operations**: Should work without any prompts
   - **New terminals**: SSH keys automatically available

5. **Verify it's working:**
   ```bash
   ssh-add -l  # Should show your loaded keys
   git push    # Should work without passphrase prompt
   ```

### **Alternative: Traditional Keyring Approaches**

For KWallet or GNOME Keyring, follow the same steps but use:
- `pam-kwallet.nix` (KDE-specific)
- `pam-gnome-keyring.nix` (GNOME-specific)

## Troubleshooting

### **Keychain Issues**
- **Keys still require passphrase**:
  - Check if keychain is running: `ps aux | grep keychain`
  - Verify keys are detected: `ssh-add -l`
  - Check shell init: `echo $SSH_AUTH_SOCK`
- **PAM not triggering keychain**:
  - Check systemd service: `systemctl --user status ssh-keychain-unlock`
  - Look at logs: `journalctl --user -u ssh-keychain-unlock`
- **GUI password dialog not appearing**:
  - Verify SSH_ASKPASS: `echo $SSH_ASKPASS`
  - Test manually: `SSH_ASKPASS_REQUIRE=force ssh-add ~/.ssh/id_camelot`

### **Traditional Keyring Issues**
- **KWallet not unlocking**: Check that your KWallet password matches your login password
- **GNOME Keyring issues**: Verify the keyring daemon is running: `ps aux | grep gnome-keyring`
- **Keys still require passphrase**: Ensure you've rebooted after applying the configuration

## Security Notes

### **Keychain Approach**
- **Login-based unlock**: SSH keys unlocked when you log in with your user password
- **Session-based**: Keys auto-lock after 8 hours of inactivity
- **Multi-session**: Same unlocked keys shared across all terminals safely
- **YubiKey compatible**: Works alongside your existing YubiKey setup
- **Fallback security**: If keychain fails, you still get prompted for passphrases

### **General Security**
- Make sure your user password is strong since it may protect your SSH keys
- Consider using hardware tokens (YubiKey) for additional security (already configured in your setup)
- These solutions work with your existing YubiKey authentication
- Keys are never stored unencrypted - only the agent holds them in memory

## Advanced Configuration

### **Adding More SSH Keys**
To add additional SSH keys to keychain, modify the key list in your chosen configuration:

```nix
# In pam-ssh-keychain.nix or pam-ssh-keychain-simple.nix
for key in id_camelot id_yubikey id_work id_personal; do
  if [ -f "$USER_HOME/.ssh/$key" ]; then
    SSH_KEYS="$SSH_KEYS $key"
  fi
done
```

### **Customizing Timeout**
Change the 8-hour (480 minute) timeout:

```nix
eval $(keychain --eval --agents ssh --timeout 1440 id_camelot)  # 24 hours
# OR
eval $(keychain --eval --agents ssh --timeout 60 id_camelot)    # 1 hour
```

### **Per-Host Key Selection**
You can configure different keys for different hosts using your existing hostSpec:

```nix
SSH_KEYS="id_camelot"
# Add host-specific keys
if [ "$(hostname)" = "work-laptop" ]; then
  SSH_KEYS="$SSH_KEYS id_work"
fi
```
