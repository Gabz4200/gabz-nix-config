# Building and Using the Custom Installation ISO

## 🚀 Quick Start

### Build the ISO

```bash
# From your NixConf directory
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# The ISO will be in: result/iso/
ls -lh result/iso/
```

### Write to USB Drive

**Option 1: Using Ventoy (Recommended - Preserves USB data)**

1. Install Ventoy on your USB drive (one-time setup): https://www.ventoy.net/
2. Simply copy the ISO to the Ventoy USB drive:
   ```bash
   cp result/iso/nixos-*.iso /path/to/ventoy/usb/
   ```
3. Boot from Ventoy and select the ISO from the menu

**Option 2: Using dd (Destructive - Erases USB)**

```bash
# Find your USB drive (e.g., /dev/sdb)
lsblk

# Write the ISO (DESTROYS all data on USB!)
sudo dd if=result/iso/nixos-hermes-installer.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

**Note**: Ventoy works perfectly with this ISO - no special configuration needed!

### Boot from USB

1. Insert USB drive into Hermes laptop
2. Boot and select USB from boot menu (usually F12, F10, or ESC)
3. Select "NixOS" from boot menu

## 🎯 What's Included in the ISO

The custom ISO includes:

✅ **Automated installer script** at `/etc/install-hermes.sh`
✅ **All necessary tools**: git, disko dependencies, NetworkManager, sops, age
✅ **NetworkManager** for easy WiFi setup (use `nmtui`)
✅ **Auto-login** as user `nixos`
✅ **Clear instructions** shown on login

## ⚠️ CRITICAL: How Disko Partitioning Works

### Understanding the Installation Process

When you run the automated installer, here's **exactly** what happens:

1. **Clone your config** from Git → `/home/nixos/NixConf`
2. **Create LUKS password** → Stored temporarily in `/tmp/luks-password`
3. **Run Disko** → This is the critical step that partitions your disk
4. **Copy config** → To `/mnt/persist/etc/nixos` (persistent storage)
5. **Install NixOS** → Using your configuration
6. **Set passwords** → User password for login
7. **Clean up** → Securely delete LUKS password file

### Disko Partitioning (Step 3 - THE DESTRUCTIVE PART)

**Command executed:**
```bash
nix run github:nix-community/disko -- \
  --mode disko \
  ./hosts/hermes/hardware-configuration.nix
```

**What this does:**
1. ❌ **DESTROYS ALL DATA** on `/dev/sda` (no undo!)
2. Creates GPT partition table
3. Creates 3 partitions:
   - `/dev/sda1` (1MB) - BIOS boot partition
   - `/dev/sda2` (1GB) - EFI System Partition (ESP) → `/boot`
   - `/dev/sda3` (rest) - LUKS encrypted partition
4. Encrypts `/dev/sda3` with your LUKS password (from `/tmp/luks-password`)
5. Opens encrypted device as `/dev/mapper/hermes`
6. Creates Btrfs filesystem with label `hermes`
7. Creates Btrfs subvolumes:
   - `@root` → `/` (ephemeral, will be wiped on boot)
   - `@root-blank` → Snapshot for wiping (read-only)
   - `@nix` → `/nix` (persistent)
   - `@persist` → `/persist` (persistent)
   - `@swap` → `/swap` (swapfile)
8. Mounts everything to `/mnt`

**Post-Disko mount structure:**
```bash
/mnt                          # Root (ephemeral)
├── /mnt/boot                 # ESP (/dev/sda2)
├── /mnt/nix                  # Nix store (persistent)
├── /mnt/persist              # Your data (persistent)
└── /mnt/swap                 # Swap partition
```

### Verification After Disko

The installer script verifies mounts:
```bash
mount | grep /mnt
# Should show:
# /dev/mapper/hermes on /mnt type btrfs
# /dev/mapper/hermes on /mnt/nix type btrfs
# /dev/mapper/hermes on /mnt/persist type btrfs
# /dev/sda2 on /mnt/boot type vfat
```

If `/mnt` is not mounted, **Disko failed** and installation aborts.

## 📋 Installation Steps from ISO

### 1. Boot the ISO

You'll see:
```
Welcome to NixOS Custom Installer!

Automated installer: /etc/install-hermes.sh

To install NixOS on Hermes:
  sudo /etc/install-hermes.sh

REQUIREMENTS:
- Internet connection (use 'nmtui' for WiFi)
- This will DESTROY ALL DATA on /dev/sda!

Configuration repo: https://github.com/Gabz4200/gabz-nix-config.git

For manual installation, see:
  https://github.com/Gabz4200/gabz-nix-config/blob/main/INSTALLATION.md

Press Enter to continue...
```

### 2. Connect to WiFi (if needed)

```bash
# Use NetworkManager TUI
nmtui
# Select: Activate a connection
# Choose your WiFi network, enter password

# Verify connectivity
ping -c 3 github.com
```

### 3. Run the automated installer

```bash
# Option 1: Use default repo (recommended)
sudo /etc/install-hermes.sh

# Option 2: Use custom repo (for forks/testing)
sudo /etc/install-hermes.sh https://github.com/youruser/your-fork.git
```

**Default repository**: `https://github.com/Gabz4200/gabz-nix-config.git`

**The installer will:**

#### Phase 1: Repository Setup
- Clone your NixConf from GitHub
- Change to the config directory

#### Phase 2: LUKS Password Setup  
- Prompt for disk encryption password (twice)
- Save to `/tmp/luks-password`

#### Phase 3: 🚨 DESTRUCTIVE PARTITIONING 🚨
- **DESTROYS ALL DATA on /dev/sda**
- Run Disko to:
  - Create partitions
  - Encrypt with LUKS
  - Format with Btrfs
  - Create subvolumes
  - Mount to `/mnt`

#### Phase 4: Mount Verification
- Check mounts are correct
- Abort if Disko failed

#### Phase 5: Configuration Deployment
- Copy NixConf to `/mnt/persist/etc/nixos`

#### Phase 6: NixOS Installation
- Run `nixos-install --flake .#hermes`
- This can take 10-30 minutes

#### Phase 7: User Password
- Set password for user `gabz`

#### Phase 7: Age Keys & Password Setup
- **Option A**: If you have your age private key:
  - Installer prompts for the key
  - Saves to `/mnt/persist/home/gabz/.config/sops/age/keys.txt`
  - Your SOPS-encrypted password works immediately on first boot
  
- **Option B**: If you don't have your age key:
  - Installer sets a temporary password
  - After first boot, you must:
    1. Copy age key to `~/.config/sops/age/keys.txt`
    2. `chmod 600 ~/.config/sops/age/keys.txt`
    3. `sudo nixos-rebuild switch --flake ~/NixConf#hermes`
    4. Your SOPS password takes effect

**Your age public key**: `age1760zlef5j6zxaart39wpzgyerpu000uf406t2kvl2c8nlyscygyse6c67x`

#### Phase 8: Cleanup
- Securely delete LUKS password file
- Display success message

### 4. Reboot

```bash
sudo reboot
# Remove USB drive
# Boot from internal drive
```

### 5. First Boot

1. **LUKS password prompt**: Enter your disk encryption password
   - This decrypts your `/dev/sda3` partition
   - Opens it as `/dev/mapper/hermes`
   
2. **Login screen**: Username `gabz`, password you set during install

3. **Your system is ready!** 🎉
   - Root filesystem is ephemeral (wipes on reboot)
   - Your data is in `/persist` (permanent)
   - See INSTALLATION.md for understanding the system

## 🔍 Disko Configuration Deep Dive

### How the Partitioning Really Works

The Disko configuration in `hosts/hermes/hardware-configuration.nix` defines exactly what happens to your disk:

```nix
disko.devices.disk.main = {
  device = "/dev/sda";  # ← YOUR ENTIRE DISK (100% wiped!)
  type = "disk";
  content = {
    type = "gpt";
    partitions = {
      # 1MB BIOS boot (for legacy boot compatibility)
      boot = { size = "1M"; type = "EF02"; };
      
      # 1GB EFI System Partition (your /boot)
      ESP = {
        size = "1G";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
        };
      };
      
      # Rest of disk: LUKS encrypted
      luks = {
        size = "100%";
        content = {
          type = "luks";
          name = "hermes";  # Opens as /dev/mapper/hermes
          passwordFile = "/tmp/luks-password";  # ← Reads password here
          settings.allowDiscards = true;        # TRIM for SSD
          content = {
            type = "btrfs";
            extraArgs = [ "-f" "-L" "hermes" ];
            subvolumes = {
              # Ephemeral root (wiped every boot)
              "@root" = { mountpoint = "/"; };
              "@root-blank" = { };  # Snapshot for wiping
              
              # Persistent data
              "@nix" = { mountpoint = "/nix"; };
              "@persist" = { mountpoint = "/persist"; };
              "@swap" = { mountpoint = "/swap"; swapfile.size = "12G"; };
            };
          };
        };
      };
    };
  };
};
```

### The Disko Command Executed

```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  ./hosts/hermes/hardware-configuration.nix
```

**What happens step-by-step:**

1. **Wipe disk** → All data on `/dev/sda` DESTROYED (no undo!)
2. **Create GPT** → New partition table
3. **Create 3 partitions**:
   - `/dev/sda1` (1MB) → BIOS boot
   - `/dev/sda2` (1GB) → ESP (FAT32) → `/boot`
   - `/dev/sda3` (rest) → LUKS encrypted
4. **Encrypt `/dev/sda3`** → Password from `/tmp/luks-password`
5. **Open as `/dev/mapper/hermes`** → LUKS device mapper
6. **Format Btrfs** → Label "hermes", compression zstd:12
7. **Create subvolumes**:
   - `@root` → `/` (ephemeral)
   - `@root-blank` → (snapshot, read-only)
   - `@nix` → `/nix` (persistent)
   - `@persist` → `/persist` (persistent)
   - `@swap` → `/swap` (swapfile)
8. **Mount to `/mnt`** → Ready for installation

### Post-Disko Mount Structure

After successful Disko run, you'll have:

```
/mnt                          # Root (Btrfs @root subvol, ephemeral)
├── /mnt/boot                 # ESP (/dev/sda2, FAT32)
├── /mnt/nix                  # Nix store (Btrfs @nix subvol, persistent)
├── /mnt/persist              # User data (Btrfs @persist subvol, persistent)
│   ├── /mnt/persist/home     # User homes
│   ├── /mnt/persist/etc      # Persistent /etc files
│   └── /mnt/persist/var      # Persistent /var files
└── /mnt/swap                 # Swap (Btrfs @swap subvol, 12GB swapfile)
```

**Verify mounts after Disko:**
```bash
mount | grep /mnt
# Expected output:
# /dev/mapper/hermes on /mnt type btrfs (rw,relatime,compress=zstd:12,space_cache=v2,subvol=/@root)
# /dev/mapper/hermes on /mnt/nix type btrfs (rw,relatime,compress=zstd:12,space_cache=v2,subvol=/@nix)
# /dev/mapper/hermes on /mnt/persist type btrfs (rw,relatime,compress=zstd:12,space_cache=v2,subvol=/@persist)
# /dev/sda2 on /mnt/boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1)
```

### Why the passwordFile Mechanism Works

**During installation:**
1. Installer creates `/tmp/luks-password` with your password
2. Disko reads this file to encrypt the partition
3. After installation, file is securely deleted (`shred -u`)

**At boot time:**
1. No `/tmp/luks-password` exists (ephemeral root!)
2. Systemd prompts for password interactively
3. Password unlocks `/dev/sda3` → opens `/dev/mapper/hermes`
4. System boots normally

**Security:**
- Password never stored permanently
- Only exists briefly during install in tmpfs
- Shredded after use

## 🔐 Secrets Management (SOPS/age)

### Understanding Your Password Setup

Your NixOS configuration uses **SOPS (Secrets OPerationS)** with **age encryption** for managing secrets, including your user password.

**In your config:**
```nix
# hosts/common/users/gabz/default.nix
users.users.gabz = {
  hashedPasswordFile = config.sops.secrets.gabz-password.path;
  # Password comes from encrypted secrets.yaml
};

sops.secrets.gabz-password = {
  sopsFile = ../../secrets.yaml;  # Encrypted with age
  neededForUsers = true;
};
```

**Your secrets.yaml contains:**
- Encrypted password hash (needs age key to decrypt)
- Public key: `age1760zlef5j6zxaart39wpzgyerpu000uf406t2kvl2c8nlyscygyse6c67x`
- Private key: **You must have this!** (format: `AGE-SECRET-KEY-...`)

### Age Key Scenarios During Installation

#### Scenario 1: You Have Your Age Private Key ✅

**During ISO installation:**
1. Installer asks: "Do you have your age private key?"
2. You answer: `y`
3. Paste your private key starting with `AGE-SECRET-KEY-...`
4. Installer saves to `/mnt/persist/home/gabz/.config/sops/age/keys.txt`
5. Sets permissions: `chmod 600`

**On first boot:**
- System decrypts `secrets.yaml` using your age key
- Reads encrypted password hash
- Login works with your SOPS-encrypted password ✓

#### Scenario 2: You Don't Have Your Age Key ⚠️

**During ISO installation:**
1. Installer asks: "Do you have your age private key?"
2. You answer: `n`
3. Installer sets a **temporary password** for user `gabz`
4. Warns you to set up age key after boot

**On first boot:**
- Login with temporary password
- **SOPS fails** (no age key to decrypt secrets)
- System falls back to temporary password

**You must then:**
```bash
# 1. Copy your age private key
mkdir -p ~/.config/sops/age
nano ~/.config/sops/age/keys.txt
# Paste: AGE-SECRET-KEY-1...
chmod 600 ~/.config/sops/age/keys.txt

# 2. Rebuild system
sudo nixos-rebuild switch --flake ~/NixConf#hermes

# 3. Your SOPS password now works
# Next login will use the encrypted password from secrets.yaml
```

#### Scenario 3: Generate New Age Key 🆕

If you lost your age key, you need to:

**Step 1: Generate new key**
```bash
# On the installed system or any machine with 'age'
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
cat ~/.config/sops/age/keys.txt
# Shows:
# Public key: age1...
# AGE-SECRET-KEY-1...
```

**Step 2: Update secrets.yaml with new public key**
```bash
cd ~/NixConf
# Edit secrets.yaml recipient to new public key
sops updatekeys hosts/common/secrets.yaml

# Or re-encrypt entirely:
sops -d hosts/common/secrets.yaml > temp.yaml
# Edit age recipient in secrets.yaml
sops -e temp.yaml > hosts/common/secrets.yaml
rm temp.yaml
```

**Step 3: Rebuild**
```bash
sudo nixos-rebuild switch --flake ~/NixConf#hermes
```

### Where is the Age Key Stored?

**Location**: `/persist/home/gabz/.config/sops/age/keys.txt`

**Why this location?**
- `/persist` = Survives reboots (persistent storage)
- `~/.config/sops/age/` = Standard SOPS key location
- Bind-mounted to `~/.config/sops/age/keys.txt` via impermanence

**Backup your age key!** Without it, you cannot decrypt secrets.yaml!

### What's Encrypted in secrets.yaml?

Currently just:
- `gabz-password`: Your hashed user password

You can add more secrets:
```bash
# Enter dev shell (has sops)
nix develop

# Edit secrets
sops hosts/common/secrets.yaml

# Add new secrets:
# my-api-key: "secret123"
# database-password: "hunter2"
```

### SOPS Architecture Summary

```
secrets.yaml (encrypted)
    ↓
  [age encryption with your public key]
    ↓
  System boot → reads age private key from ~/.config/sops/age/keys.txt
    ↓
  Decrypts secrets.yaml
    ↓
  Mounts decrypted secrets to /run/secrets/
    ↓
  hashedPasswordFile points to /run/secrets/gabz-password
    ↓
  Login uses decrypted password hash ✓
```

**Without age key**: SOPS cannot decrypt → password not available → login fails (unless temporary password set)

## 🚨 Critical Troubleshooting

### Disko Fails During Installation

**Symptom:** Mount verification fails, `/mnt` not mounted

**Possible Causes:**

1. **Wrong disk device:**
   ```bash
   # Check your actual disk
   lsblk
   
   # If it's /dev/nvme0n1 instead of /dev/sda:
   cd /home/nixos/NixConf
   # Edit hardware-configuration.nix
   sed -i 's|/dev/sda|/dev/nvme0n1|g' hosts/hermes/hardware-configuration.nix
   
   # Re-run installer
   sudo /etc/install-hermes.sh
   ```

2. **Disk already mounted:**
   ```bash
   # Unmount everything
   sudo umount -R /mnt 2>/dev/null || true
   
   # Close LUKS device if open
   sudo cryptsetup close hermes 2>/dev/null || true
   
   # Re-run installer
   sudo /etc/install-hermes.sh
   ```

3. **Disk has existing partitions:**
   ```bash
   # Wipe partition table (DESTRUCTIVE!)
   sudo wipefs -a /dev/sda
   
   # Or use sgdisk
   sudo sgdisk --zap-all /dev/sda
   
   # Re-run installer
   sudo /etc/install-hermes.sh
   ```

**Debug Disko:**
```bash
# Check what Disko is trying to do
nix run github:nix-community/disko -- \
  --mode disko \
  --dry-run \
  ./hosts/hermes/hardware-configuration.nix

# Check kernel messages
dmesg | tail -50

# Check systemd journal
journalctl -xe
```

### LUKS Password Issues

**Symptom:** Password rejected at boot, "Failed to open encryption"

**Causes:**

1. **Typo during installation** (passwords didn't match confirmation)
2. **Keyboard layout different at boot** (e.g., entered in QWERTY, booting with AZERTY)

**Recovery:**

```bash
# Boot from ISO again
# Unlock manually
sudo cryptsetup luksOpen /dev/sda3 hermes
# Enter your password

# Mount your data
sudo mount -o subvol=@persist /dev/mapper/hermes /mnt
cd /mnt
# Your files are safe!

# Option 1: Change LUKS password
sudo cryptsetup luksChangeKey /dev/sda3

# Option 2: Re-install (your data in @persist is safe)
sudo umount -R /mnt
sudo cryptsetup close hermes
# Re-run installer, will ask for new password
```

**Prevent this:**
- Type password carefully during installation
- Test password before confirming
- Use same keyboard layout during install and boot

### WiFi Not Working After Install

**Symptom:** No WiFi networks visible, can't connect

**Causes:**
- NetworkManager connections not persisted (but they should be!)
- Realtek 8821CE driver not loaded

**Debug:**
```bash
# Check driver
lsmod | grep rtw88
# Should show rtw88_8821ce

# If not loaded:
sudo modprobe rtw88_8821ce

# Check NetworkManager
systemctl status NetworkManager

# Check for saved connections
ls /persist/etc/NetworkManager/system-connections/
```

**Fix:**
```bash
# Reconnect WiFi (will persist now)
nmtui
# Select: Activate a connection
# Choose network, enter password

# Verify it's saved
ls -la /persist/etc/NetworkManager/system-connections/
# Should show your connection file
```

**Persistent connections location:**
- Configured in: `hosts/common/global/optin-persistence.nix`
- Saved to: `/persist/etc/NetworkManager/system-connections/`
- Bind-mounted to: `/etc/NetworkManager/system-connections/`

### Ephemeral Root Not Working

**Symptom:** Files created in `/` persist across reboots (should be wiped!)

**Check setup:**
```bash
# Verify subvolumes exist
sudo btrfs subvolume list / | grep root
# Should show both @root and @root-blank

# Check boot service
systemctl status restore-root.service
# Should show: Active

# Check boot.initrd.postDeviceCommands in config
nixos-option boot.initrd.postDeviceCommands
```

**Fix:**

Ensure `hosts/common/optional/ephemeral-btrfs.nix` is imported:

```nix
# In hosts/hermes/default.nix
imports = [
  # ...
  ../common/optional/ephemeral-btrfs.nix  # ← Must be here!
];
```

Rebuild:
```bash
sudo nixos-rebuild switch --flake ~/NixConf#hermes
sudo reboot
```

### Data Loss: "My files disappeared!"

**Symptom:** Files created in home directory vanish after reboot

**Cause:** Files created outside persistent directories

**Understanding persistence:**

✅ **Persistent** (survives reboot):
- `~/Desktop`, `~/Documents`, `~/Downloads`, `~/Pictures`
- `~/Music`, `~/Videos`, `~/Public`, `~/Templates`
- `~/NixConf`, `~/Sync`
- `~/.ssh`, `~/.config/sops`, `~/.local/share`
- `~/.config/Code`, `.vscode`, `.cargo`, `.npm`

❌ **Ephemeral** (wiped on reboot):
- `~/random-file.txt` (not in persisted directory)
- `~/.cache` (intentionally ephemeral)
- `/tmp`, `/var/tmp`

**Check what's persisted:**
```nix
# In home/gabz/global/default.nix
home.persistence."/persist/home/gabz" = {
  directories = [
    # List of persistent directories
  ];
  files = [
    # List of persistent files
  ];
};
```

**Recover from snapshot (if recent):**
```bash
# List Btrfs snapshots
sudo btrfs subvolume list /

# Your data might be in @persist
ls /persist/home/gabz/

# Check if file is there
find /persist -name "your-file.txt"
```

**Add new persistent directory:**
```nix
# In home/gabz/global/default.nix
home.persistence."/persist/home/gabz".directories = [
  # ... existing ...
  "MyNewFolder"  # ← Add this
];

# Rebuild
home-manager switch --flake ~/NixConf#gabz@hermes
```

## 🔧 Customizing the ISO

### Adding More Packages

Edit `iso-config.nix`:

```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  neovim
  firefox
  # etc.
];
```

### Changing Target Disk

If your laptop uses `/dev/nvme0n1` instead of `/dev/sda`:

**Option 1: Edit before building ISO**
```bash
# Edit hardware-configuration.nix before building
sed -i 's|/dev/sda|/dev/nvme0n1|g' hosts/hermes/hardware-configuration.nix

# Rebuild ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

**Option 2: Edit from booted ISO**
```bash
# Boot ISO, clone repo, then edit
cd /home/nixos/NixConf
sed -i 's|/dev/sda|/dev/nvme0n1|g' hosts/hermes/hardware-configuration.nix

# Run installer
sudo /etc/install-hermes.sh
```

### Changing ISO Name

Edit `iso-config.nix`:

```nix
isoImage = {
  isoName = "my-custom-name.iso";
  volumeID = "MY_CUSTOM_ID";
};
```

## 🎯 What Gets Persisted vs Wiped

### ✅ Persisted (Survives Reboot)

**System-level** (from `hosts/common/global/optin-persistence.nix`):
```
/nix                    # Nix store (all packages)
/persist                # All persistent data
/boot                   # Bootloader, kernels
/etc/NetworkManager/system-connections  # WiFi passwords
/etc/ssh                # SSH host keys
/var/log                # System logs (journal)
```

**User-level** (from `home/gabz/global/default.nix`):

Stored in `/persist/home/gabz/`, bind-mounted to `~`:
```
~/Desktop               # Desktop files
~/Documents             # Documents
~/Downloads             # Downloads
~/Pictures              # Pictures
~/Music                 # Music
~/Videos                # Videos
~/Public                # Public share
~/Templates             # Templates
~/NixConf               # Your NixOS config (critical!)
~/Sync                  # Syncthing folder

~/.ssh                  # SSH keys
~/.config/sops          # Secrets (age keys)
~/.local/share          # App data
~/.config/Code          # VS Code settings
.vscode                 # VS Code workspace
.cargo, .rustup         # Rust toolchain
.npm, .node_repl_history  # Node.js
.config/github-copilot  # Copilot auth
```

### ❌ Wiped Every Boot (Ephemeral)

**System:**
```
/                       # Root filesystem (except /nix, /persist, /boot)
/tmp                    # Temporary files
/var/tmp                # Variable temp
/etc/*                  # Most of /etc (except persisted paths)
```

**User:**
```
~/.cache                # Cache (intentionally ephemeral)
~/random-file.txt       # Any file not in persistent directory!
~/.bash_history         # Shell history (not persisted by default)
```

**What this means:**

✅ **Good:**
- System always boots fresh and clean
- Malware in `/` gets wiped
- No cruft accumulation
- Explicit about what matters

❌ **Watch out:**
- Files must be in persistent directories
- Random downloads/files in `~` → **will be deleted!**
- Use `~/Downloads`, `~/Documents`, etc.

### How to Add Persistence

**For user data:**

Edit `home/gabz/global/default.nix`:
```nix
home.persistence."/persist/home/gabz" = {
  directories = [
    # ... existing ...
    "MyProject"  # ← Add your directory
  ];
  files = [
    ".my-important-config"  # ← Add specific files
  ];
};
```

**For system data:**

Edit `hosts/common/global/optin-persistence.nix`:
```nix
environment.persistence."/persist" = {
  directories = [
    # ... existing ...
    "/var/lib/myservice"  # ← Add system directories
  ];
};
```

**Rebuild:**
```bash
# User changes
home-manager switch --flake ~/NixConf#gabz@hermes

# System changes
sudo nixos-rebuild switch --flake ~/NixConf#hermes
```

## 🛠 ISO Build Troubleshooting

### ISO Build Fails

**Error: `path does not exist`**
```bash
# Verify flake outputs
nix flake show
# Should list: nixosConfigurations.iso

# Try verbose build
nix build .#nixosConfigurations.iso.config.system.build.isoImage --show-trace

# Clean and rebuild
nix-collect-garbage -d
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

**Error: `attribute 'iso' missing`**

Ensure `flake.nix` has the ISO output:
```nix
nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs outputs;};
  modules = [./iso-config.nix];
};
```

### ISO is Very Large

The ISO includes tools for installation. To reduce size:

1. Remove unnecessary packages from `iso-config.nix`
2. The ISO is typically 800MB-1.2GB (acceptable for installation media)

### USB Won't Boot

- Ensure UEFI/Legacy boot mode matches your system (Hermes uses UEFI)
- Try different USB ports (USB 2.0 sometimes more compatible)
- Verify USB write with: `sudo cmp result/iso/*.iso /dev/sdX`
- Try alternative tools: Ventoy, Rufus (Windows), Etcher

### WiFi Not Working on ISO

```bash
# Check interface
ip link show

# Bring up interface
sudo ip link set wlan0 up

# Use nmtui (easiest)
nmtui

# Or nmcli
nmcli device wifi list
nmcli device wifi connect "SSID" password "password"

# Or wpa_supplicant
wpa_passphrase "SSID" "password" | sudo tee /etc/wpa_supplicant.conf
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
sudo dhcpcd wlan0
```

## 🧪 Testing the ISO

### Test in QEMU (Virtual Machine)

```bash
# Build ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Run in QEMU
nix-shell -p qemu --run "
  qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cdrom result/iso/*.iso \
    -boot d
"

# With virtual disk (test full installation)
nix-shell -p qemu --run "
  # Create virtual disk
  qemu-img create -f qcow2 test-disk.qcow2 50G
  
  # Boot ISO with virtual disk
  qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cdrom result/iso/*.iso \
    -drive file=test-disk.qcow2,format=qcow2 \
    -boot d
"
```

### Test Installation Flow

1. Boot QEMU with ISO + virtual disk
2. Run installer: `sudo /etc/install-hermes.sh`
3. Watch it partition virtual disk (safe to test)
4. Verify each phase completes
5. Reboot VM and test LUKS unlock

## 📦 Building on Different Systems

### On Non-NixOS Linux

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Clone config
git clone https://github.com/yourusername/NixConf
cd NixConf

# Build ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Result in result/iso/
ls -lh result/iso/
```

### On NixOS

```bash
# Clone and build
git clone https://github.com/yourusername/NixConf
cd NixConf
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

### Remote Build (from non-NixOS)

```bash
# Build on remote NixOS machine
nix build \
  --builders 'ssh://nixos-builder x86_64-linux' \
  .#nixosConfigurations.iso.config.system.build.isoImage
```

## 🔄 Updating the ISO

### When to Rebuild

- Monthly: Get latest security updates
- Before installation: Ensure current packages
- After config changes: Test new features

### Update Process

```bash
cd ~/NixConf

# Update all flake inputs
nix flake update

# Or specific inputs
nix flake lock --update-input nixpkgs

# Rebuild ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Verify
ls -lh result/iso/
```

### Version Your ISOs

```bash
# Build with date tag
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Copy with version
cp result/iso/*.iso ~/nixos-hermes-$(date +%Y-%m-%d).iso

# Keep multiple versions
ls -lh ~/nixos-hermes-*.iso
# nixos-hermes-2025-01-15.iso
# nixos-hermes-2025-02-20.iso  ← latest
```

## 📚 Resources & Next Steps

### Documentation in This Repo

📖 **Installation Guides:**
- `INSTALLATION.md` - Comprehensive guide (400+ lines)
  - Architecture explanation
  - Manual installation steps
  - Understanding ephemeral root
  - Troubleshooting
  - Philosophy and design decisions

- `INSTALLATION-CHEATSHEET.md` - Quick command reference
  - 9-step installation
  - Copy-paste commands
  - Emergency recovery

- `INSTALLATION-SUMMARY.md` - Overview
  - High-level architecture
  - Key concepts
  - Quick orientation

📋 **Configuration Files:**
- `hosts/hermes/hardware-configuration.nix` - Disko disk config
- `hosts/common/global/optin-persistence.nix` - System persistence
- `home/gabz/global/default.nix` - User persistence
- `iso-config.nix` - This ISO configuration

### External Resources

🔧 **Tools:**
- [Disko](https://github.com/nix-community/disko) - Declarative disk partitioning
- [Impermanence](https://github.com/nix-community/impermanence) - Opt-in persistence
- [SOPS-nix](https://github.com/Mic92/sops-nix) - Secrets management

📚 **Concepts:**
- [Erase Your Darlings](https://grahamc.com/blog/erase-your-darlings) - Ephemeral root philosophy
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official docs
- [NixOS Wiki](https://wiki.nixos.org/) - Community wiki

### Post-Installation

After successful installation:

1. **Understand your system:**
   ```bash
   # Read the philosophy
   cat ~/NixConf/INSTALLATION.md
   
   # Check what's persisted
   cat ~/NixConf/hosts/common/global/optin-persistence.nix
   cat ~/NixConf/home/gabz/global/default.nix
   ```

2. **Customize configuration:**
   ```bash
   cd ~/NixConf
   # Make changes
   
   # Rebuild system
   sudo nixos-rebuild switch --flake .#hermes
   
   # Or just user config
   home-manager switch --flake .#gabz@hermes
   ```

3. **Manage secrets:**
   ```bash
   # Enter dev shell (has sops)
   nix develop
   
   # Edit secrets
   sops hosts/common/secrets.yaml
   ```

4. **Update system:**
   ```bash
   # Update flake inputs
   nix flake update
   
   # Rebuild with updates
   sudo nixos-rebuild switch --flake .#hermes
   
   # Update Home Manager
   home-manager switch --flake .#gabz@hermes
   ```

5. **Add persistence for new data:**
   ```bash
   # Edit persistence config
   vim home/gabz/global/default.nix
   
   # Add directory to persist
   # directories = [ ... "MyNewFolder" ];
   
   # Rebuild
   home-manager switch --flake .#gabz@hermes
   ```

## 💡 Pro Tips

✅ **Before Installation:**
- Build ISO on fast machine (can take 10-30 min)
- Test in QEMU first to verify installation flow
- Ensure Hermes is plugged in (installation drains battery)
- Have WiFi password ready

✅ **During Installation:**
- Double-check LUKS password (typos mean data loss!)
- Use same keyboard layout for password entry and boot
- Don't interrupt Disko step (disk corruption risk)
- nixos-install can take 20-30 minutes (be patient)

✅ **After Installation:**
- Test LUKS unlock immediately after first reboot
- Connect WiFi first boot (will persist automatically)
- Verify persistence: create file in `~/Downloads`, reboot, check it's there
- Read INSTALLATION.md to understand ephemeral root

✅ **Maintenance:**
- Rebuild ISO monthly for updates
- Version your ISOs: `nixos-hermes-YYYY-MM-DD.iso`
- Keep one ISO on USB for emergencies
- Test new ISOs in QEMU before real hardware

## 🎯 Installation Workflow Summary

```
┌─────────────────────────────────────┐
│  1. Build ISO (any Nix system)      │
│     nix build .#...iso               │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  2. Write to USB                     │
│     dd if=*.iso of=/dev/sdX          │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  3. Boot Hermes from USB             │
│     Auto-login as nixos              │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  4. Connect WiFi                     │
│     nmtui → Activate connection      │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  5. Run Installer                    │
│     sudo /etc/install-hermes.sh      │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  Installation Phases:                │
│  ✓ Clone repo from GitHub            │
│  ✓ Set LUKS password                 │
│  ✓ Disko partitions /dev/sda         │
│  ✓ Verify mounts                     │
│  ✓ Copy config to /persist           │
│  ✓ nixos-install (10-30 min)         │
│  ✓ Set user password                 │
│  ✓ Cleanup                           │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  6. Reboot                           │
│     Remove USB, boot from /dev/sda   │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  7. First Boot                       │
│  ✓ LUKS password (decrypt disk)      │
│  ✓ Login (user: gabz, your password) │
│  ✓ System ready!                     │
└─────────────────────────────────────┘
```

---

## ✅ Ready to Install?

Your custom ISO makes NixOS installation on Hermes **foolproof**:

✅ Automated disk partitioning with Disko
✅ LUKS full-disk encryption
✅ Ephemeral root with Btrfs snapshots  
✅ Opt-in persistence (data won't disappear!)
✅ All tools included in ISO
✅ Step-by-step automated installer
✅ SOPS/age secrets support
✅ Works with Ventoy or dd

### 🎬 Fully Automated Installation Script

The ISO includes `/etc/install-hermes.sh` which automates **everything**:

**What it does automatically:**
1. ✅ Clones your NixConf from GitHub
2. ✅ Prompts for LUKS password (with confirmation)
3. ✅ Warns before disk destruction (requires typing "YES")
4. ✅ Runs Disko to partition `/dev/sda`
5. ✅ Verifies mounts succeeded (aborts if failed)
6. ✅ Copies config to persistent storage
7. ✅ Runs `nixos-install --flake .#hermes`
8. ✅ Handles age key setup (if you have it)
9. ✅ Sets user password (temporary or SOPS)
10. ✅ Securely deletes LUKS password file
11. ✅ Provides clear next steps

**What you need to provide:**
- WiFi password (via `nmtui`)
- GitHub repo URL (or use default)
- LUKS encryption password
- Age private key (optional, but recommended)
- User password (if no age key)
- Confirmation before disk wipe (type "YES")

**No manual intervention needed beyond these inputs!**

**Build the ISO:**
```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

**Write to USB:**
- **Ventoy**: Just copy ISO to Ventoy USB drive
- **dd**: `sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress`

**Boot and install:**
```bash
sudo /etc/install-hermes.sh https://github.com/yourusername/NixConf.git
```

For questions or issues, see `INSTALLATION.md` or the troubleshooting sections above.
