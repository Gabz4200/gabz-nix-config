# NixOS Installation Guide with Disko (Hermes)

This guide provides a **foolproof, step-by-step** installation process for the Hermes laptop using Disko for automatic disk partitioning with LUKS encryption and ephemeral root filesystem.

## 📖 What You're Installing

This configuration creates a **highly secure, ephemeral NixOS system**:

- **LUKS Full Disk Encryption** - Your entire drive is encrypted
- **Ephemeral Root** - System resets to a clean state on every boot
- **Opt-in Persistence** - Only explicitly listed data survives reboots
- **Btrfs Subvolumes** - Efficient snapshots and compression
- **Automated Partitioning** - Disko handles everything

### System Architecture

```
/dev/sda (Physical Disk)
├── /dev/sda1 (1MB BIOS Boot)
├── /dev/sda2 (1GB ESP - /boot)
└── /dev/sda3 (LUKS Encrypted)
    └── /dev/mapper/hermes (Btrfs)
        ├── @root → / (ephemeral, wiped on boot)
        ├── @nix → /nix (persistent, packages)
        ├── @persist → /persist (persistent, your data)
        └── @swap → /swap (12GB swapfile for hibernation)
```

## ⚠️ CRITICAL WARNINGS

- **ALL DATA ON `/dev/sda` WILL BE PERMANENTLY DESTROYED**
- Your system uses **ephemeral root** - files outside `/persist` and `/nix` are deleted on every reboot
- LUKS encryption password will be required **at every boot**
- **You need TWO different passwords** - one for disk encryption, one for user login
- **Back up any existing data before proceeding**
- **Save your LUKS password securely** - losing it means losing all data

## 📋 Pre-Installation Checklist

Before you begin, make sure you have:

- [ ] **NixOS Installation USB/ISO** - Booted and running
- [ ] **Internet connection** - WiFi or Ethernet working
- [ ] **Backed up all existing data** on the target disk
- [ ] **Identified the correct disk** (this guide assumes `/dev/sda`)
- [ ] **Strong LUKS password ready** - You'll type this at every boot
- [ ] **User password ready** - For logging in after boot
- [ ] **This guide accessible** - Print the cheatsheet or have it on your phone
- [ ] **Your GitHub repo URL** - To clone your NixConf
- [ ] **(Optional) SOPS/age keys** - For encrypted secrets

### Important Notes

1. **Disk Identification**: Run `lsblk` to confirm `/dev/sda` is correct
2. **Password Strategy**: LUKS password should be different from user password
3. **Time Required**: Full installation takes 15-30 minutes
4. **Network**: Installer needs internet to download packages

## Step-by-Step Installation

### 1. Verify the Target Disk

```bash
# List all disks - make sure /dev/sda is the correct one!
lsblk
```

**STOP HERE** if `/dev/sda` is not your target disk. You need to edit `hosts/hermes/hardware-configuration.nix` first.

### 2. Get Your Configuration

```bash
# Install git
nix-shell -p git

# Clone your configuration (replace with your repo URL)
git clone https://github.com/yourusername/NixConf /mnt/etc/nixos
cd /mnt/etc/nixos
```

### 3. Create LUKS Password File

**This is the most important step!** Choose a strong password that you'll remember.

```bash
# Create a password file with your chosen LUKS password
# Choose a STRONG password - you'll type this at EVERY boot
echo -n "YourStrongPasswordHere" > /tmp/luks-password

# Secure the file
chmod 600 /tmp/luks-password

# Verify it was created correctly (should show your password)
cat /tmp/luks-password
```

**✏️ WRITE DOWN THIS PASSWORD NOW!**
- This is your **disk encryption** password
- You'll need it **every time you boot**
- Losing it means **losing all data**
- Keep it in a password manager or secure location

**Password Tips:**
- Use at least 20 characters
- Mix letters, numbers, and symbols
- Avoid common words or patterns
- Consider using a passphrase like "correct-horse-battery-staple-2025"

### 4. Run Disko to Partition and Encrypt

```bash
# This will:
# - Wipe /dev/sda
# - Create partitions (boot, ESP, encrypted LUKS)
# - Format and mount everything
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  /mnt/etc/nixos/hosts/hermes/hardware-configuration.nix
```

**This takes 2-5 minutes.** You'll see:
- Partition creation messages
- LUKS encryption setup (using your password from `/tmp/luks-password`)
- Btrfs formatting and subvolume creation
- Mount operations

### 5. Verify Mounts

```bash
# Check that everything is mounted correctly
mount | grep /mnt
```

You should see:
- `/dev/mapper/hermes` on `/mnt` (btrfs root)
- `/dev/mapper/hermes` on `/mnt/nix` (btrfs /nix)
- `/dev/mapper/hermes` on `/mnt/persist` (btrfs /persist)
- `/dev/sda2` on `/mnt/boot` (ESP)

### 6. Move Configuration to Persist

Since your root filesystem is ephemeral, the config needs to be in a persistent location.

```bash
# Copy config to the persistent partition so it survives reboots
sudo mkdir -p /mnt/persist/etc/nixos
sudo cp -r /mnt/etc/nixos/* /mnt/persist/etc/nixos/

# Verify the copy
ls -la /mnt/persist/etc/nixos/
```

**Why this matters:** After reboot, `/etc/nixos` (on ephemeral root) will be empty. Your config will be in `/persist/etc/nixos` where you can access it.

### 7. Install NixOS

```bash
# Install the system
sudo nixos-install --flake /mnt/persist/etc/nixos#hermes
```

This will:
- Build the system configuration
- Install all packages
- Set up SOPS secrets (if keys are available)

**Note:** You may see errors about `gabz-password` secret if you don't have the SOPS keys yet. That's okay - we'll set a password manually.

### 8. Set User Password

```bash
# Set a temporary password for user 'gabz'
# (You can change this later via SOPS)
sudo nixos-enter --root /mnt -c 'passwd gabz'
```

Enter a password when prompted (this is your USER password, not the LUKS password).

### 9. Clean Up and Reboot

```bash
# Remove the password file for security
shred -u /tmp/luks-password

# Reboot
sudo reboot
```

## First Boot

### What to Expect

1. **Systemd-boot menu** - Select NixOS
2. **LUKS password prompt** - Enter the password you created in step 3
3. **Ephemeral root wipe** - May see btrfs messages (this is normal)
4. **Login prompt** - Enter username: `gabz`, password: what you set in step 8

### If WiFi Doesn't Work

The Realtek 8821CE driver may need a reboot to load properly:

```bash
# Check if the driver is loaded
lsmod | grep 8821ce

# If not, reboot once more
sudo reboot
```

## Understanding Your System

### Ephemeral Root
- **Wiped on every boot:** `/` (root filesystem)
- **Persistent:** `/nix` (packages), `/persist` (your data)
- **Your home:** `/home/gabz` → links to `/persist/home/gabz`

### What Survives Reboots (Persistence Model)

This system uses **opt-in persistence** - everything is wiped except what you explicitly choose to keep.

#### ✅ Persistent (Survives Reboots)

**System Level:**
- ✅ Nix store (`/nix`) - All packages and system files
- ✅ System logs (`/persist/var/log`)
- ✅ SSH host keys (`/persist/etc/ssh`) - Server identity stays consistent
- ✅ NetworkManager WiFi passwords (`/persist/etc/NetworkManager`)
- ✅ Machine ID, systemd state, fingerprint data

**User Level (Your Data):**
- ✅ **All XDG directories**: Desktop, Documents, Downloads, Music, Pictures, Public, Templates, Videos
- ✅ **Your NixOS config**: `~/NixConf`
- ✅ **SSH keys**: `~/.ssh`
- ✅ **SOPS/age keys**: `~/.config/sops` (critical for encrypted secrets!)
- ✅ **VSCode**: Settings, extensions, workspace data
- ✅ **Development tools**: Direnv allow list, Nix cache, shell history
- ✅ **GitHub Copilot**: Authentication state
- ✅ **Syncthing**: `~/Sync` folder (if enabled)

#### ❌ Ephemeral (Wiped Every Boot)

- ❌ Root filesystem (`/`) - Fresh system every boot
- ❌ Temporary files (`/tmp`, `/var/tmp`)
- ❌ Files created in `/root`, `/etc` (unless explicitly persisted)
- ❌ Any file in `~` that's not in the persistence list above
- ❌ Downloaded files outside Downloads folder
- ❌ Application caches not explicitly persisted

**Example:** If you create `~/myfile.txt`, it will **disappear on reboot** unless you move it to a persisted directory like `~/Documents/myfile.txt`.

### Emergency: Skip Root Wipe

If you need to debug something across reboots:

```bash
sudo touch /persist/dont-wipe
sudo reboot
```

Remove this file when done debugging.

## Post-Installation Tasks

### 1. First Login

After reboot, you'll see:
1. **GRUB/Systemd-boot menu** - Select "NixOS"
2. **LUKS password prompt** - Enter your disk encryption password (from step 3)
3. **Login screen** - Username: `gabz`, Password: your user password (from step 8)

### 2. Verify the System

```bash
# Check ephemeral root is working
ls / # Should be mostly empty except /nix, /persist, etc.

# Check persistence
ls /persist/home/gabz # Should show your directories

# Check that config is accessible
ls /persist/etc/nixos # Should show your NixConf

# Verify impermanence bind mounts
findmnt -t btrfs # Shows all btrfs mounts

# Check what's persisted
ls -la ~ # Hidden dirs like .ssh should be symlinks to /persist
```

### 3. Update System (Important!)

```bash
# Navigate to your config
cd /persist/etc/nixos

# Update and rebuild (pulls latest packages)
sudo nixos-rebuild switch --flake .#hermes

# Apply home manager
home-manager switch --flake .#gabz@hermes
```

### 4. Set Up Development Environment

```bash
# Clone your config to persistent home directory
cd ~
git clone https://github.com/yourusername/NixConf ~/NixConf

# Enter dev shell
cd ~/NixConf
nix develop

# Now you can make changes and rebuild
```

### 5. Set Up SOPS Secrets (Optional but Recommended)

If you have SOPS/age keys for encrypted password management:

```bash
# Copy your age keys to the persistent location
mkdir -p ~/.config/sops/age
cp /path/to/your/keys.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Verify secrets can be decrypted
cd ~/NixConf
sops hosts/common/secrets.yaml

# Rebuild to use encrypted password
sudo nixos-rebuild switch --flake .#hermes
```

### 6. Test Ephemeral Root

**Important:** Verify the wipe mechanism works correctly!

```bash
# Create a test file in ephemeral location
sudo touch /root/test-file.txt
echo "This should disappear" > ~/ephemeral-test.txt

# Reboot
sudo reboot

# After reboot, check both files are gone
ls /root/test-file.txt # Should not exist
ls ~/ephemeral-test.txt # Should not exist

# But persistent data remains
ls ~/Documents # Should still have your files
```

## 🔧 Troubleshooting

### "Can't unlock LUKS device on boot"
**Symptoms:** Black screen asking for password, but it's rejected

**Solutions:**
- Double-check you're entering the LUKS password (from step 3), NOT the user password
- The password is case-sensitive - check Caps Lock
- NumLock state might affect number key input
- Try typing slowly and carefully
- If truly forgotten, **you cannot recover** - need to reinstall

### "User password doesn't work"
**Symptoms:** Login screen rejects your password

**Solutions:**
- LUKS password (boot) and user password (login) are DIFFERENT
- Make sure you're typing the user password from step 8
- Reset from TTY: `Ctrl+Alt+F2`, login as root (if enabled), run `passwd gabz`
- Boot to recovery mode and run `passwd gabz`

### "WiFi not working after first boot"
**Symptoms:** No WiFi networks showing, NetworkManager not working

**Solutions:**
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check if driver loaded
lsmod | grep 8821ce

# If driver missing, reboot once more (sometimes needed for Realtek)
sudo reboot

# Check WiFi hardware
ip link show
```

### "Files disappeared after reboot"
**Symptoms:** Documents, downloads, or configs are gone

**This is normal for ephemeral root!**

**Understanding the issue:**
- Only files in `/persist` survive reboots
- Files created in non-persisted locations are wiped
- Check if the file was in a persisted directory

**Solutions:**
1. **Always save important files** to persisted directories:
   - `~/Documents`, `~/Downloads`, `~/Desktop`, etc.
   - `~/NixConf` (your config)
   - Any directory listed in `home/gabz/global/default.nix`

2. **Add new directories to persistence:**
   ```bash
   # Edit persistence config
   cd ~/NixConf
   # Add directory to home/gabz/global/default.nix under persistence."/persist".directories
   # Rebuild
   sudo nixos-rebuild switch --flake .#hermes
   ```

3. **Emergency: Skip next wipe**
   ```bash
   sudo touch /persist/dont-wipe
   sudo reboot
   # System won't wipe on next boot - gives you time to save files
   # Remember to remove this file when done!
   ```

### "System won't boot after update"
**Symptoms:** Stuck at boot, crashes, or boot loop

**Solutions:**
1. **Boot into previous generation:**
   - At boot menu, select an older NixOS generation
   - Press `↓` to see all available generations
   
2. **Rollback from working generation:**
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

3. **Boot from USB and fix:**
   ```bash
   # Mount the encrypted partition
   sudo cryptsetup open /dev/sda3 hermes
   sudo mount -o subvol=root /dev/mapper/hermes /mnt
   sudo mount -o subvol=persist /dev/mapper/hermes /mnt/persist
   sudo mount -o subvol=nix /dev/mapper/hermes /mnt/nix
   sudo mount /dev/sda2 /mnt/boot
   
   # Enter the system
   sudo nixos-enter --root /mnt
   
   # Fix config or rollback
   cd /persist/etc/nixos
   # Make fixes
   nixos-rebuild switch --flake .#hermes
   ```

### "Out of disk space"
**Symptoms:** Errors about disk full, can't install packages

**Solutions:**
```bash
# Clean up old generations
sudo nix-collect-garbage --delete-older-than 7d

# Clean up boot entries
sudo /run/current-system/bin/switch-to-configuration boot

# Check disk usage
df -h
du -sh /nix/*
btrfs filesystem usage /

# For Btrfs: balance can free space
sudo btrfs balance start -dusage=50 /
```

### "Forgot to persist important data"
**Symptoms:** Realized too late that data wasn't persisted

**Prevention:**
1. **List what you want to persist BEFORE installation**
2. **Test the wipe** (see Post-Installation step 6)
3. **Gradually add persistence** as you discover needs

**Recovery (if caught immediately):**
```bash
# If you haven't rebooted yet, copy to persist
cp -r ~/important-directory /persist/home/gabz/

# Then add to persistence config for future
```

### "How do I add persistence for a new app?"
**Example:** Want to persist a new application's data

**Steps:**
```bash
cd ~/NixConf

# Edit home/gabz/global/default.nix
# Add to persistence."/persist".directories:
#   ".config/newapp"  # For configs
#   ".local/share/newapp"  # For data

# Or for system-level persistence, edit:
# hosts/common/global/optin-persistence.nix

# Rebuild
sudo nixos-rebuild switch --flake .#hermes
home-manager switch --flake .#gabz@hermes
```

## 📚 Understanding Your System

### Password Management

You have **THREE** different password concepts:

1. **LUKS Disk Encryption Password** (created in step 3)
   - **When:** Typed at boot, black screen, before system loads
   - **Purpose:** Decrypt the entire disk
   - **Storage:** In your brain/password manager (NOT on disk)
   - **If forgotten:** Cannot decrypt disk, all data is lost forever

2. **User Login Password** (set in step 8)
   - **When:** Typed at login screen, after system boots
   - **Purpose:** Log in as user `gabz`
   - **Storage:** Hashed in `/etc/shadow` (can be reset)
   - **If forgotten:** Can reset from recovery mode

3. **SOPS Encrypted Password** (optional, for automation)
   - **When:** Used by system to auto-set user password
   - **Purpose:** Automate user password from encrypted secrets
   - **Storage:** In `hosts/common/secrets.yaml` encrypted with age/GPG
   - **If forgotten:** Can regenerate with SOPS

**Golden Rule:** LUKS ≠ User ≠ SOPS. They're independent!

### Ephemeral Root Philosophy

**Why use ephemeral root?**

1. **Security:** Malware can't persist across reboots
2. **Cleanliness:** No accumulated cruft or leftover configs
3. **Reliability:** Every boot is a fresh, known-good state
4. **Declarative:** System state is fully defined in your config

**How it works:**

```
Boot Sequence:
1. GRUB/systemd-boot loads
2. LUKS prompts for password → decrypts disk
3. Mount /persist, /nix (persistent subvolumes)
4. Mount / from root-blank snapshot (fresh state)
5. Impermanence creates bind mounts from /persist → /home
6. System boots with clean root + persistent user data
```

**Mental model:**
- Think of `/` as **RAM** - disappears when powered off
- Think of `/persist` as **your hard drive** - survives reboots
- Your config declares what to "remember" vs "forget"

### Directory Structure Explained

```
/                          # Ephemeral, wiped every boot
├── nix/                   # Packages (persistent via subvolume)
├── persist/               # Your data (persistent via subvolume)
│   ├── etc/nixos/        # Your config lives here!
│   ├── home/gabz/        # Actual storage for persisted user data
│   │   ├── Documents/
│   │   ├── .ssh/
│   │   └── ...
│   └── var/log/          # System logs
├── home/                  # Ephemeral except persisted directories
│   └── gabz/             # Most of this is ephemeral
│       ├── Documents/    # → Bind mount from /persist/home/gabz/Documents
│       ├── .ssh/         # → Bind mount from /persist/home/gabz/.ssh
│       └── temp.txt      # ← WIPED on reboot (not persisted!)
└── swap/                  # Swapfile subvolume
    └── swapfile          # 12GB for hibernation
```

### How to Work with This System

**DO:**
- ✅ Save all important files to persisted directories
- ✅ Add new persistence rules BEFORE saving data
- ✅ Use `~/Documents`, `~/Downloads`, etc. for everything important
- ✅ Test with dummy data first
- ✅ Commit config changes to git
- ✅ Keep SOPS keys backed up

**DON'T:**
- ❌ Create files in `~` root without checking persistence
- ❌ Assume new apps persist automatically
- ❌ Store secrets in ephemeral locations
- ❌ Forget to rebuild after changing config
- ❌ Skip testing after adding persistence rules

### Daily Workflow

**Making system changes:**
```bash
cd ~/NixConf
# Edit files
vim hosts/hermes/default.nix
# Rebuild
sudo nixos-rebuild switch --flake .#hermes
```

**Adding new persistence:**
```bash
cd ~/NixConf
# Edit home/gabz/global/default.nix
# Add ".config/myapp" to directories list
# Rebuild
home-manager switch --flake .#gabz@hermes
```

**Updating packages:**
```bash
cd ~/NixConf
nix flake update
sudo nixos-rebuild switch --flake .#hermes
```

## Files Modified

- `hosts/hermes/hardware-configuration.nix` - Added `passwordFile` for LUKS
- `INSTALLATION.md` - This guide

---

**Need help?** Check the NixOS manual or open an issue on the repo.
