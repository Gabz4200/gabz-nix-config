# Quick Installation Cheat Sheet

**⚠️ SAVES YOUR LIFE - PRINT THIS OR TAKE A PHOTO! ⚠️**

## 🎯 Quick Facts

- **What:** Encrypted NixOS with ephemeral root (wipes on reboot)
- **Disk:** `/dev/sda` will be **COMPLETELY ERASED**
- **Time:** 15-30 minutes total
- **Passwords:** You need TWO different passwords (LUKS + user)

## 📝 Before You Start

- [ ] Backed up all data on `/dev/sda`
- [ ] Have strong LUKS password ready (20+ chars)
- [ ] Have user password ready  
- [ ] Internet connection working
- [ ] This cheatsheet accessible (printed/phone)

## 🚀 The 9 Commands (In Order)

```bash
# ============================================
# STEP 1: Get your configuration
# ============================================
nix-shell -p git
git clone https://github.com/yourusername/NixConf /mnt/etc/nixos
cd /mnt/etc/nixos

# ============================================
# STEP 2: Create LUKS password file
# ⚠️ CHANGE "YourStrongPasswordHere" FIRST!
# ============================================
echo -n "YourStrongPasswordHere" > /tmp/luks-password
chmod 600 /tmp/luks-password
# WRITE DOWN THIS PASSWORD NOW! ✏️

# ============================================
# STEP 3: Run Disko (DESTROYS /dev/sda!)
# ⚠️ NO GOING BACK AFTER THIS!
# ============================================
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko /mnt/etc/nixos/hosts/hermes/hardware-configuration.nix

# ============================================
# STEP 4: Verify mounts (should see 4 mounts)
# ============================================
mount | grep /mnt
# Should show: /mnt, /mnt/nix, /mnt/persist, /mnt/boot

# ============================================
# STEP 5: Copy config to persistent storage
# ============================================
sudo mkdir -p /mnt/persist/etc/nixos
sudo cp -r /mnt/etc/nixos/* /mnt/persist/etc/nixos/

# ============================================
# STEP 6: Install NixOS (takes 10-20 min)
# ============================================
sudo nixos-install --flake /mnt/persist/etc/nixos#hermes

# ============================================
# STEP 7: Set user password (DIFFERENT from LUKS!)
# ============================================
sudo nixos-enter --root /mnt -c 'passwd gabz'

# ============================================
# STEP 8: Security cleanup
# ============================================
shred -u /tmp/luks-password

# ============================================
# STEP 9: Reboot and pray 🙏
# ============================================
sudo reboot
```

## 🔐 Two Passwords - DON'T MIX THEM UP!

| When You Type It | Which Password | What It's For |
|-----------------|---------------|---------------|
| **Boot (black screen with prompt)** | 🔑 LUKS password (step 2) | Decrypt the disk |
| **Login (graphical/text login)** | 👤 User password (step 7) | Log in as gabz |

**Remember:** 
- LUKS password = **Before** system boots (disk encryption)
- User password = **After** system boots (login)
- They are **COMPLETELY DIFFERENT** passwords!

## 🎬 After First Boot

### First Login Sequence
1. **Boot menu** → Select "NixOS"
2. **Black screen** → Type LUKS password (from step 2) ← Press Enter
3. **Login prompt** → Username: `gabz`, Password: user password (from step 7)

### Initial Setup Commands
```bash
# Navigate to your config (in persistent storage)
cd /persist/etc/nixos

# Update system
sudo nixos-rebuild switch --flake .#hermes

# Apply home manager
home-manager switch --flake .#gabz@hermes

# Clone config to home directory
git clone https://github.com/yourusername/NixConf ~/NixConf
```

## 🚨 Emergency Commands

### WiFi Issues
```bash
sudo systemctl restart NetworkManager
# Still broken? Reboot once: sudo reboot
```

### Skip Root Wipe (Emergency Only!)
```bash
sudo touch /persist/dont-wipe  # Prevents wipe on NEXT boot
sudo reboot
# Remove when done: sudo rm /persist/dont-wipe
```

### Reset User Password
```bash
# If you forgot user password (NOT LUKS password!)
# Boot to recovery mode or press Ctrl+Alt+F2
sudo passwd gabz
```

### Boot Previous Generation
```bash
# At boot menu, press ↓ to see older generations
# Select a working one if current is broken
```

## 📊 What Survives Reboots?

### ✅ Persistent (Keeps Forever)
- `/nix` - All packages
- `/persist` - Your data
- `~/Documents`, `~/Downloads`, `~/Desktop`, `~/Pictures`, etc.
- `~/NixConf` - Your configuration
- `~/.ssh` - SSH keys  
- `~/.config/sops` - Encryption keys ⚠️ CRITICAL!
- VSCode settings, shell history, WiFi passwords

### ❌ Ephemeral (Wiped Every Boot)
- `/` (root filesystem) - Fresh every boot
- `/tmp` - Temporary files
- `~/random-file.txt` - Files not in persisted dirs
- Anything in `/etc` or `/root` (unless explicitly persisted)

**Rule of Thumb:** If it's not in a persisted directory, it's GONE on reboot!

## 🧠 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| LUKS password rejected | Check Caps Lock, type slowly, verify it's the DISK password (step 2) |
| User password rejected | This is DIFFERENT from LUKS - use password from step 7 |
| WiFi not working | `sudo systemctl restart NetworkManager` then reboot if needed |
| Files disappeared | Normal! Only persisted dirs survive. Move files to `~/Documents` |
| Can't boot after update | At boot menu, select previous generation (press ↓) |
| Out of disk space | `sudo nix-collect-garbage --delete-older-than 7d` |

## 📚 Important Paths

```bash
/persist/etc/nixos/        # Your NixOS config (survives reboots)
~/NixConf/                 # Your config clone (in home, persisted)
~/.config/sops/            # Encryption keys (BACKUP THESE!)
~/.ssh/                    # SSH keys (persisted)
/etc/nixos/                # Empty on ephemeral root!
```

## 🔄 Common Post-Install Tasks

```bash
# Update packages
cd ~/NixConf
nix flake update
sudo nixos-rebuild switch --flake .#hermes

# Add new persistent directory
# Edit: home/gabz/global/default.nix
# Add to: persistence."/persist".directories = [ "NewFolder" ];
# Then: home-manager switch --flake .#gabz@hermes

# Install new package
# Edit: hosts/hermes/default.nix or home/gabz/hermes.nix
# Add to: environment.systemPackages or home.packages
# Then: sudo nixos-rebuild switch --flake .#hermes
```

## ⚡ Pro Tips

1. **Test the wipe:** Create `~/test.txt`, reboot, verify it's gone
2. **Backup SOPS keys:** `~/.config/sops/age/` is CRITICAL - back it up!
3. **Use git:** Commit config changes before rebuilding
4. **Keep passwords safe:** Store LUKS password in password manager
5. **Print this cheat sheet:** Keep physical copy during install

---

**📖 Full detailed guide:** See `INSTALLATION.md`  
**🆘 Stuck?** Check the Troubleshooting section in full guide  
**💡 Remember:** Only `/nix` and `/persist` survive reboots!
