# 🚀 ISO Quick Start Guide

## TL;DR - Installation in 5 Steps

1. **Build ISO**: `nix build .#nixosConfigurations.iso.config.system.build.isoImage`
2. **Write to USB**: Copy `result/iso/*.iso` to Ventoy USB (or use `dd`)
3. **Boot from USB**: Select ISO from Ventoy menu
4. **Connect WiFi**: `nmtui`
5. **Install**: `sudo /etc/install-hermes.sh https://github.com/yourusername/NixConf.git`

That's it! The script does everything automatically.

---

## ✅ What You Need Before Installing

### Required:
- [ ] **Internet connection** (WiFi password ready)
- [ ] **GitHub repo URL** (where your NixConf is hosted)
- [ ] **LUKS password** (for disk encryption, needed at every boot)

### Highly Recommended:
- [ ] **Age private key** (format: `AGE-SECRET-KEY-1...`)
  - This decrypts your `secrets.yaml` 
  - Without it, you'll need a temporary password initially
  - Your public key: `age1760zlef5j6zxaart39wpzgyerpu000uf406t2kvl2c8nlyscygyse6c67x`

### Optional:
- [ ] Backup of any data on `/dev/sda` (will be completely erased!)

---

## 📀 USB Options: Ventoy vs dd

### Option 1: Ventoy (Recommended) ✅

**Pros:**
- Doesn't erase USB data
- Multi-boot support
- Just copy/paste ISO files
- No special commands needed

**Setup (one-time):**
1. Download Ventoy: https://www.ventoy.net/
2. Install to USB drive
3. Copy ISO: `cp result/iso/*.iso /path/to/ventoy/`
4. Boot and select from Ventoy menu

**Works perfectly with this ISO - no configuration needed!**

### Option 2: dd (Traditional) ⚠️

**Pros:**
- Standard method
- Works everywhere

**Cons:**
- Erases entire USB
- Single-purpose USB

**Commands:**
```bash
lsblk  # Find your USB (e.g., /dev/sdb)
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

---

## 🔐 Password & Secrets Setup

### Understanding Your Two Passwords

1. **LUKS Password** (Disk Encryption)
   - Asked during installation
   - Needed at **every boot** to decrypt disk
   - Stored temporarily in `/tmp/luks-password` during install
   - Securely deleted after installation
   - Prompted interactively at boot (not stored anywhere)

2. **User Password** (Login)
   - **Encrypted in `secrets.yaml`** with SOPS/age
   - Needs your age private key to decrypt
   - **OR** temporary password if you don't have age key

### Age Key Scenarios

#### ✅ You Have Age Private Key (Recommended)

**During installation:**
```
Installer asks: "Do you have your age private key?"
You answer: y
Paste your key: AGE-SECRET-KEY-1qqpzry9x8gf2tvdw0s3jn54khce6mua7l...
✓ Key saved to /persist/home/gabz/.config/sops/age/keys.txt
✓ Your SOPS password will work immediately on first boot
```

**First boot:**
- LUKS password → decrypt disk ✓
- Login with your SOPS-encrypted password ✓
- Everything works immediately ✓

#### ⚠️ You Don't Have Age Key

**During installation:**
```
Installer asks: "Do you have your age private key?"
You answer: n
⚠️  Installer sets temporary password
⚠️  You must set up age key after first boot
```

**First boot:**
- LUKS password → decrypt disk ✓
- Login with **temporary password** ✓
- SOPS secrets won't work (no age key)

**Then you must:**
```bash
# 1. Copy/create age key
mkdir -p ~/.config/sops/age
nano ~/.config/sops/age/keys.txt  # Paste: AGE-SECRET-KEY-...
chmod 600 ~/.config/sops/age/keys.txt

# 2. Rebuild
sudo nixos-rebuild switch --flake ~/NixConf#hermes

# 3. Next login uses SOPS password ✓
```

#### 🆕 Generate New Age Key (If Lost)

```bash
# Generate new key
age-keygen -o ~/.config/sops/age/keys.txt
cat ~/.config/sops/age/keys.txt
# Note the public key: age1...

# Update secrets.yaml with new public key
cd ~/NixConf
sops updatekeys hosts/common/secrets.yaml

# Rebuild
sudo nixos-rebuild switch --flake .#hermes
```

---

## 🎬 What The Installer Does Automatically

The `/etc/install-hermes.sh` script handles everything:

### Phase 1: Repository ✓
- Clones NixConf from GitHub
- Changes to config directory

### Phase 2: LUKS Password ✓
- Prompts for encryption password (twice for confirmation)
- Saves to `/tmp/luks-password`
- Validates passwords match

### Phase 3: Disk Partitioning ✓
- **Warns**: ALL DATA ON /dev/sda WILL BE DESTROYED
- **Requires confirmation**: Type "YES" to continue
- Runs Disko:
  ```bash
  nix run github:nix-community/disko -- \
    --mode disko \
    ./hosts/hermes/hardware-configuration.nix
  ```
- Creates:
  - `/dev/sda1` (1MB) - BIOS boot
  - `/dev/sda2` (1GB) - EFI System Partition → `/boot`
  - `/dev/sda3` (rest) - LUKS encrypted
- Encrypts `/dev/sda3` with your LUKS password
- Opens as `/dev/mapper/hermes`
- Formats with Btrfs (zstd:12 compression)
- Creates subvolumes:
  - `@root` → `/` (ephemeral, wiped on boot)
  - `@root-blank` → snapshot for wiping
  - `@nix` → `/nix` (persistent)
  - `@persist` → `/persist` (persistent)
  - `@swap` → `/swap` (12GB swapfile)
- Mounts everything to `/mnt`

### Phase 4: Mount Verification ✓
- Checks `/mnt` is mounted
- Verifies all subvolumes mounted correctly
- **Aborts if Disko failed** (prevents data loss)

### Phase 5: Config Deployment ✓
- Creates `/mnt/persist/etc/nixos`
- Copies entire NixConf to persistent storage

### Phase 6: NixOS Installation ✓
- Runs: `nixos-install --flake /mnt/persist/etc/nixos#hermes`
- Downloads and installs all packages
- **Takes 10-30 minutes** (be patient!)

### Phase 7: Secrets & Password ✓
- Asks if you have age private key
- **If yes**: Saves key to `/persist/home/gabz/.config/sops/age/keys.txt`
- **If no**: Sets temporary password, warns about age key setup

### Phase 8: Cleanup ✓
- Securely deletes `/tmp/luks-password` with `shred -u`
- Displays success message
- Lists next steps

### Phase 9: Reboot 🎉
- Remove USB drive
- `sudo reboot`
- Enter LUKS password at boot
- Login with user password
- **Your system is ready!**

---

## ⚠️ Common Issues & Solutions

### "Passwords don't match!"
- **Fix**: Carefully re-enter LUKS password, type slowly

### "Disko failed, /mnt not mounted"
- **Cause**: Wrong disk device or disk in use
- **Fix**: Check disk with `lsblk`, ensure it's `/dev/sda`
- **Fix**: Unmount: `umount -R /mnt 2>/dev/null; cryptsetup close hermes`

### "SOPS secrets not working after install"
- **Cause**: No age private key
- **Fix**: Copy key to `~/.config/sops/age/keys.txt`, rebuild

### "Can't login after first boot"
- **Cause**: No age key, SOPS password unavailable
- **Fix**: Use temporary password, then set up age key

### "ISO won't boot from Ventoy"
- **Fix**: Ensure Ventoy is up to date
- **Fix**: Try different USB port (USB 2.0 sometimes better)

---

## 🎯 Quick Reference

**Build ISO:**
```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

**Install (from booted ISO):**
```bash
# 1. Connect WiFi
nmtui

# 2. Run installer
sudo /etc/install-hermes.sh https://github.com/yourusername/NixConf.git
```

**After first boot (if no age key):**
```bash
# Set up age key
mkdir -p ~/.config/sops/age
nano ~/.config/sops/age/keys.txt  # Paste key
chmod 600 ~/.config/sops/age/keys.txt

# Rebuild
sudo nixos-rebuild switch --flake ~/NixConf#hermes
```

**Update system:**
```bash
cd ~/NixConf
nix flake update
sudo nixos-rebuild switch --flake .#hermes
```

---

## 📚 More Information

- **Detailed guide**: `ISO-BUILD.md` (comprehensive, 1000+ lines)
- **Installation philosophy**: `INSTALLATION.md` (architecture, ephemeral root)
- **Quick commands**: `INSTALLATION-CHEATSHEET.md` (copy-paste reference)
- **Overview**: `INSTALLATION-SUMMARY.md` (high-level concepts)

---

## ✅ Pre-Flight Checklist

Before installing, ensure:

- [ ] ISO built successfully
- [ ] USB drive ready (Ventoy or raw)
- [ ] Hermes plugged in (installation drains battery)
- [ ] WiFi password available
- [ ] GitHub repo URL ready (update placeholder in script!)
- [ ] Age private key accessible (optional but recommended)
- [ ] LUKS password chosen (strong, memorable)
- [ ] Backup of any data on `/dev/sda` (if needed)
- [ ] Understand ephemeral root concept (read `INSTALLATION.md`)

**Ready to install!** 🚀
