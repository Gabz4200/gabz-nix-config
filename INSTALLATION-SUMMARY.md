# Installation Summary

## ✅ Your NixConf is Ready to Install!

This repository is fully configured for a **secure, ephemeral NixOS installation** with:

- ✅ LUKS full disk encryption
- ✅ Ephemeral root filesystem (wipes on every boot)
- ✅ Opt-in persistence for data you care about
- ✅ Automated partitioning with Disko
- ✅ Btrfs with compression and snapshots
- ✅ NetworkManager, SSH, and WiFi persistence configured
- ✅ VSCode, development tools, and SOPS keys persisted
- ✅ Comprehensive installation guides

## 📚 Documentation

1. **`INSTALLATION.md`** - Full detailed guide with:
   - Pre-installation checklist
   - Step-by-step tutorial
   - System architecture explanation
   - Comprehensive troubleshooting
   - Understanding ephemeral root
   - Post-installation tasks

2. **`INSTALLATION-CHEATSHEET.md`** - Quick reference:
   - 9 commands for installation
   - Password reminders
   - Emergency commands
   - Common tasks
   - **Print this or save to your phone!**

## 🚀 Quick Start

### Before Installing

1. **Backup everything** on your target disk (`/dev/sda`)
2. **Prepare two passwords:**
   - LUKS disk encryption password (20+ characters)
   - User login password
3. **Have this repo URL ready** for cloning during install

### Installation Process

```bash
# 1. Boot NixOS installer
# 2. Follow INSTALLATION-CHEATSHEET.md (9 steps)
# 3. Reboot and login
# 4. Run post-install setup
```

**Time required:** 15-30 minutes

## 🔐 Persistence Configuration

### What's Persisted

**System Level:**
- SSH host keys → `/persist/etc/ssh`
- NetworkManager WiFi → `/persist/etc/NetworkManager/system-connections`
- System logs → `/persist/var/log`

**User Level:**
- **All XDG directories:** Desktop, Documents, Downloads, Music, Pictures, Public, Templates, Videos
- **NixConf repository:** `~/NixConf`
- **Security keys:** `~/.ssh`, `~/.config/sops`
- **Development:** `.local/bin`, direnv, nix cache, shell history
- **Apps:** VSCode, GitHub Copilot, Syncthing

### What's NOT Persisted (Wiped Every Boot)

- Root filesystem `/` (fresh on every boot)
- Temporary files `/tmp`
- Any file in `~` not in the list above
- Application caches (unless explicitly added)

## 🎯 Key Features

### Security
- Full disk encryption (LUKS)
- Ephemeral root prevents persistent malware
- Secrets managed with SOPS
- Firewall and fail2ban ready

### Reliability
- Declarative configuration
- Atomic upgrades with rollback
- Btrfs snapshots
- Known-good state on every boot

### Performance
- Btrfs compression (zstd:12)
- SSD optimizations
- Swap file for hibernation (12GB)
- Nix binary cache

## ⚠️ Important Warnings

1. **Data Destruction:** Installation will **completely erase** `/dev/sda`
2. **Password Critical:** Losing LUKS password = **losing all data forever**
3. **Ephemeral Root:** Files outside `/persist` **disappear on reboot**
4. **Two Passwords:** LUKS (boot) and user (login) are **different**
5. **SOPS Keys:** Backup `~/.config/sops/age/` - needed for encrypted secrets

## 🧪 Testing Your Installation

After first boot:

```bash
# 1. Verify ephemeral root
sudo touch /root/test-file.txt
echo "disappear" > ~/test.txt
sudo reboot
# After reboot, both should be gone

# 2. Verify persistence
echo "survive" > ~/Documents/test.txt
sudo reboot
# After reboot, this should still exist

# 3. Check bind mounts
findmnt -t btrfs
ls -la ~ # .ssh, .config, etc. should be symlinks

# 4. Verify config location
ls /persist/etc/nixos # Your config
ls ~/NixConf # Your working copy
```

## 📖 Learning Resources

### Understanding the System
- Read `INSTALLATION.md` → "Understanding Your System" section
- Study `home/gabz/global/default.nix` → persistence configuration
- Review `hosts/common/global/optin-persistence.nix` → system persistence

### Making Changes
- `hosts/hermes/default.nix` → Host-specific config
- `home/gabz/hermes.nix` → User-specific config
- `home/gabz/features/**` → Feature modules

### Adding Persistence
1. Edit `home/gabz/global/default.nix`
2. Add directory to `persistence."/persist".directories`
3. Rebuild: `home-manager switch --flake .#gabz@hermes`

## 🛠 Common Tasks Reference

### Update System
```bash
cd ~/NixConf
nix flake update
sudo nixos-rebuild switch --flake .#hermes
```

### Add New Package
```bash
# Edit config to add package
vim hosts/hermes/default.nix
# Rebuild
sudo nixos-rebuild switch --flake .#hermes
```

### Rollback
```bash
sudo nixos-rebuild switch --rollback
# Or select old generation at boot
```

### Clean Old Generations
```bash
sudo nix-collect-garbage --delete-older-than 7d
```

## 🆘 Getting Help

1. **Check `INSTALLATION.md`** → Comprehensive troubleshooting section
2. **Check `INSTALLATION-CHEATSHEET.md`** → Quick solutions table
3. **Review the config** → Everything is documented with comments
4. **Boot previous generation** → If update broke something
5. **Use recovery mode** → For password resets or emergency fixes

## 🎉 You're Ready!

Your NixConf repository is:
- ✅ Fully configured for Hermes laptop
- ✅ Tested and validated (`nix flake check` passes)
- ✅ Documented with comprehensive guides
- ✅ Ready for installation

**Next steps:**
1. Print or save `INSTALLATION-CHEATSHEET.md` to your phone
2. Review `INSTALLATION.md` for full understanding
3. Boot NixOS installer
4. Follow the guide step-by-step
5. Enjoy your secure, declarative NixOS system!

---

**Remember:** The two most important things:
1. **Don't lose your LUKS password** 🔑
2. **Backup your SOPS keys** (`~/.config/sops/age/`) 💾

Good luck! 🚀
