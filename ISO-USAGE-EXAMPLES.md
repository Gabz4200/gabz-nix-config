# ISO Installation Usage Examples

## 📋 Quick Reference

### Standard Installation (Recommended)

Uses the default repository: `https://github.com/Gabz4200/gabz-nix-config.git`

```bash
# Boot from ISO
# Connect WiFi
nmtui

# Run installer with defaults
sudo /etc/install-hermes.sh
```

---

## 🔧 Advanced Usage

### Using a Custom Repository

Override the default repo by passing it as an argument:

```bash
sudo /etc/install-hermes.sh https://github.com/youruser/your-config.git
```

### Use Cases for Custom Repo

#### 1. Testing a Fork
```bash
# You forked Gabz4200/gabz-nix-config to test changes
sudo /etc/install-hermes.sh https://github.com/youruser/gabz-nix-config.git
```

#### 2. Using a Different Branch
```bash
# Clone specific branch
git clone -b dev https://github.com/Gabz4200/gabz-nix-config.git
cd gabz-nix-config
# Build ISO from this branch, then use default installer
```

#### 3. Private Repository (HTTPS)
```bash
# Requires credentials
sudo /etc/install-hermes.sh https://username:token@github.com/youruser/private-config.git
```

#### 4. Private Repository (SSH)
```bash
# Set up SSH keys first
mkdir -p ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub  # Add to GitHub

# Then install
sudo /etc/install-hermes.sh git@github.com:youruser/private-config.git
```

---

## 🎯 Installation Workflow

### Basic Workflow (Default Repo)
```
1. Boot ISO
2. nmtui → Connect WiFi
3. sudo /etc/install-hermes.sh
4. Enter LUKS password (twice)
5. Confirm disk wipe: YES
6. Provide age key (optional)
7. Set user password (if no age key)
8. Reboot
```

### Custom Repo Workflow
```
1. Boot ISO
2. nmtui → Connect WiFi
3. (Optional) Set up SSH keys if using private repo
4. sudo /etc/install-hermes.sh <your-repo-url>
5. Enter LUKS password (twice)
6. Confirm disk wipe: YES
7. Provide age key (optional)
8. Set user password (if no age key)
9. Reboot
```

---

## 📝 Examples by Scenario

### Scenario 1: Fresh Install (You are Gabz)
```bash
# Just use defaults - your repo is hardcoded
sudo /etc/install-hermes.sh
```

### Scenario 2: Fresh Install (Different User)
```bash
# Use your own config that's based on Gabz's
sudo /etc/install-hermes.sh https://github.com/myuser/my-nixos-config.git
```

### Scenario 3: Testing Changes
```bash
# Fork repo, make changes, test with ISO
sudo /etc/install-hermes.sh https://github.com/myuser/gabz-nix-config.git
```

### Scenario 4: Offline Install (Pre-cloned)
```bash
# Not supported by script - use manual method instead
# See INSTALLATION-CHEATSHEET.md
```

---

## ⚙️ Repository Requirements

Your custom repo **must** have:

### Required Structure
```
your-repo/
├── flake.nix
│   └── nixosConfigurations.hermes  # Must exist
├── hosts/
│   └── hermes/
│       ├── default.nix
│       └── hardware-configuration.nix  # Disko config
└── home/
    └── gabz/
        └── hermes.nix
```

### Required Configuration

1. **Disko configuration** at `hosts/hermes/hardware-configuration.nix`:
   ```nix
   disko.devices.disk.main = {
     device = "/dev/sda";  # Or your disk
     # ... rest of Disko config
   };
   ```

2. **NixOS configuration** with:
   - User `gabz` defined
   - Persistence configuration (if using ephemeral root)
   - SOPS secrets (if using encrypted passwords)

3. **Flake outputs**:
   ```nix
   nixosConfigurations.hermes = lib.nixosSystem {
     modules = [ ./hosts/hermes ];
     # ...
   };
   ```

### Optional But Recommended

- Age keys at `/persist/home/gabz/.config/sops/age/keys.txt`
- SOPS secrets in `hosts/common/secrets.yaml`
- Installation guides (INSTALLATION.md, etc.)

---

## 🔍 Verifying Your Custom Repo

Before using a custom repo with the ISO installer:

### 1. Test Locally
```bash
# Clone your repo
git clone https://github.com/youruser/your-config.git
cd your-config

# Verify flake
nix flake show

# Should show:
# └───nixosConfigurations
#     └───hermes: NixOS configuration

# Test build
nix build .#nixosConfigurations.hermes.config.system.build.toplevel
```

### 2. Verify Disko Config
```bash
# Check Disko syntax
nix run github:nix-community/disko -- --mode disko --dry-run \
  ./hosts/hermes/hardware-configuration.nix
```

### 3. Build ISO from Your Repo
```bash
# If your repo has ISO config
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

---

## 🚨 Troubleshooting Custom Repos

### Error: "flake does not provide attribute 'nixosConfigurations.hermes'"

**Fix**: Ensure your `flake.nix` exports `nixosConfigurations.hermes`:
```nix
outputs = { self, nixpkgs, ... }: {
  nixosConfigurations.hermes = nixpkgs.lib.nixosSystem {
    modules = [ ./hosts/hermes ];
  };
};
```

### Error: "path './hosts/hermes/hardware-configuration.nix' does not exist"

**Fix**: Ensure Disko config exists at the expected path:
```bash
ls -la hosts/hermes/hardware-configuration.nix
```

### Error: "authentication failed" (Private Repo)

**Fix**: Set up authentication before installing:
```bash
# For HTTPS
git config --global credential.helper store

# For SSH
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub  # Add to GitHub
```

### Script clones wrong repo

**Check**: Verify the repo URL displayed:
```
Repository: https://github.com/youruser/your-config.git
```

If wrong, you can abort (Ctrl+C) and re-run with correct URL.

---

## 💡 Tips & Best Practices

### For Repo Maintainers

1. **Keep structure compatible** with original Gabz config
2. **Document your changes** in README
3. **Test ISO installation** in VM before real hardware
4. **Version your ISOs** when making major changes

### For Users

1. **Use default repo** unless you have a specific reason not to
2. **Fork, don't modify** if you want to test changes
3. **Keep age keys safe** - back them up before installing
4. **Test in QEMU first** if using custom repo:
   ```bash
   qemu-img create -f qcow2 test.qcow2 50G
   qemu-system-x86_64 -enable-kvm -m 4096 \
     -cdrom result/iso/*.iso \
     -drive file=test.qcow2,format=qcow2 \
     -boot d
   ```

---

## 📚 Related Documentation

- **ISO-BUILD.md**: Complete ISO building and installation guide
- **ISO-QUICK-START.md**: TL;DR quick reference
- **INSTALLATION.md**: Manual installation (without ISO)
- **INSTALLATION-CHEATSHEET.md**: Command reference

---

**Default Repository**: https://github.com/Gabz4200/gabz-nix-config.git

**Override Support**: ✅ Pass custom URL as first argument to installer script
