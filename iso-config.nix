# Custom NixOS Installation ISO Configuration
# This creates a bootable ISO with instructions to clone and install your NixConf
{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ISO metadata
  isoImage = {
    isoName = lib.mkForce "nixos-hermes-installer.iso";
    volumeID = lib.mkForce "NIXOS_HERMES";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # Enable experimental features for flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Pre-install useful tools for installation
  environment.systemPackages = with pkgs; [
    # Essential tools
    git
    vim
    helix
    wget
    curl
    rsync

    # Disk & filesystem tools
    gptfdisk
    parted
    cryptsetup
    btrfs-progs

    # Network tools
    networkmanager
    wpa_supplicant

    # Utilities
    htop
    tmux
    unzip

    # SOPS for secrets management
    sops
    age
  ];

  # Enable NetworkManager for easier WiFi setup
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Auto-login to make it easier
  services.getty.autologinUser = "nixos";

  # Create helper scripts and documentation
  environment.etc."install-hermes.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -e

      REPO_URL="''${1:-https://github.com/yourusername/NixConf.git}"

      echo "=========================================="
      echo "  NixOS Hermes Installation Helper"
      echo "=========================================="
      echo ""
      echo "This script will:"
      echo "  1. Clone your NixConf repository"
      echo "  2. Partition and encrypt /dev/sda with Disko"
      echo "  3. Install NixOS with your configuration"
      echo ""

      # Check if already cloned
      if [ ! -d "/home/nixos/NixConf" ]; then
        echo "Step 1: Cloning NixConf from: $REPO_URL"
        git clone "$REPO_URL" /home/nixos/NixConf
        cd /home/nixos/NixConf
      else
        echo "Step 1: NixConf already exists, using it..."
        cd /home/nixos/NixConf
      fi

      echo ""
      echo "Step 2: Creating LUKS password file..."
      read -sp "Enter LUKS encryption password (you'll need this at every boot): " LUKS_PASS
      echo ""
      read -sp "Confirm LUKS password: " LUKS_PASS_CONFIRM
      echo ""

      if [ "$LUKS_PASS" != "$LUKS_PASS_CONFIRM" ]; then
        echo "Passwords don't match! Aborting."
        exit 1
      fi

      echo -n "$LUKS_PASS" > /tmp/luks-password
      chmod 600 /tmp/luks-password
      echo "✓ LUKS password file created"

      echo ""
      echo "Step 3: Running Disko (THIS WILL COMPLETELY ERASE /dev/sda!)..."
      echo "⚠️  ALL DATA ON /dev/sda WILL BE PERMANENTLY DESTROYED!"
      read -p "Type 'YES' to continue: " CONFIRM
      if [ "$CONFIRM" != "YES" ]; then
        echo "Aborted."
        shred -u /tmp/luks-password
        exit 1
      fi

      echo "Running Disko partitioning..."
      nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
        --mode disko \
        ./hosts/hermes/hardware-configuration.nix

      echo ""
      echo "Step 4: Verifying mounts..."
      mount | grep /mnt
      if ! mount | grep -q "/mnt "; then
        echo "❌ Error: /mnt is not mounted! Disko may have failed."
        exit 1
      fi
      echo "✓ Disk partitioned and mounted successfully"

      echo ""
      echo "Step 5: Copying config to persistent storage..."
      mkdir -p /mnt/persist/etc/nixos
      cp -r ./* /mnt/persist/etc/nixos/
      echo "✓ Config copied to /mnt/persist/etc/nixos"

      echo ""
      echo "Step 6: Installing NixOS (this takes 10-20 minutes)..."
      nixos-install --flake /mnt/persist/etc/nixos#hermes

      echo ""
      echo "Step 7: Setting up age keys and user password..."
      echo ""
      echo "IMPORTANT: For secrets (SOPS) to work, you need your age private key."
      echo "The public key is: age1760zlef5j6zxaart39wpzgyerpu000uf406t2kvl2c8nlyscygyse6c67x"
      echo ""
      echo "Options:"
      echo "  1. Copy your existing age key to /mnt/persist/home/gabz/.config/sops/age/keys.txt"
      echo "  2. Generate a new key and update secrets.yaml later"
      echo "  3. Set a temporary password now (will be replaced by SOPS secret on first boot)"
      echo ""
      read -p "Do you have your age private key to copy? (y/n): " HAS_KEY

      if [ "$HAS_KEY" = "y" ]; then
        echo "Please provide the age private key content:"
        echo "(Paste the entire key starting with AGE-SECRET-KEY-...)"
        read -sp "Age private key: " AGE_KEY
        echo ""
        mkdir -p /mnt/persist/home/gabz/.config/sops/age
        echo "$AGE_KEY" > /mnt/persist/home/gabz/.config/sops/age/keys.txt
        chmod 600 /mnt/persist/home/gabz/.config/sops/age/keys.txt
        nixos-enter --root /mnt -c 'chown -R gabz:users /persist/home/gabz/.config'
        echo "✓ Age key installed successfully"
        echo "✓ Your SOPS-encrypted password will work on first boot"
      else
        echo ""
        echo "⚠️  Setting temporary password. You'll need to:"
        echo "    1. Boot the system with this temporary password"
        echo "    2. Set up your age key at ~/.config/sops/age/keys.txt"
        echo "    3. Rebuild: sudo nixos-rebuild switch --flake ~/NixConf#hermes"
        echo ""
        echo "Setting temporary user password for 'gabz'..."
        nixos-enter --root /mnt -c 'passwd gabz'
      fi

      fi

      echo ""
      echo "Step 8: Cleaning up..."
      shred -u /tmp/luks-password
      echo "✓ LUKS password file securely deleted"

      echo ""
      echo "=========================================="
      echo "  ✅ Installation Complete!"
      echo "=========================================="
      echo ""
      echo "Next steps:"
      echo "  1. Remove the USB drive"
      echo "  2. Reboot: sudo reboot"
      echo "  3. At boot, enter your LUKS password to decrypt disk"
      echo "  4. At login, use username 'gabz' and your password"
      echo ""
      if [ "$HAS_KEY" = "y" ]; then
        echo "✓ Your SOPS secrets are configured and will work immediately"
      else
        echo "⚠️  IMPORTANT: Set up your age key after first boot:"
        echo "    1. Copy your age private key to ~/.config/sops/age/keys.txt"
        echo "    2. chmod 600 ~/.config/sops/age/keys.txt"
        echo "    3. sudo nixos-rebuild switch --flake ~/NixConf#hermes"
        echo "    4. Your SOPS-encrypted password will then take effect"
      fi
      echo ""
      echo "⚠️  Remember: You have TWO different passwords!"
      echo "    - LUKS password = decrypt disk at boot"
      echo "    - User password = login to system"
      echo ""
    '';
    mode = "0755";
  };

  environment.etc."README-INSTALLER.txt" = {
    text = ''
      ========================================
        NixOS Hermes Installation ISO
      ========================================

      Welcome! This ISO will help you install NixOS
      with your custom Hermes configuration.

      PREREQUISITES:
      1. WiFi connection: nmtui
      2. Your NixConf repo URL ready

      AUTOMATED INSTALLATION:
      sudo /etc/install-hermes.sh [repo-url]

      Example:
      sudo /etc/install-hermes.sh https://github.com/yourusername/NixConf.git

      The script will:
      ✓ Clone your NixConf
      ✓ Create LUKS encryption password
      ✓ Partition /dev/sda with Disko
      ✓ Install NixOS
      ✓ Set user password

      MANUAL INSTALLATION:
      1. Clone config: git clone <url> ~/NixConf
      2. Follow: ~/NixConf/INSTALLATION-CHEATSHEET.md

      IMPORTANT:
      - /dev/sda will be COMPLETELY ERASED
      - You need TWO passwords: LUKS (boot) + user (login)
      - Backup any existing data first!

      ========================================
    '';
  };

  # Show welcome message on login
  programs.bash.interactiveShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] && [ "$USER" = "nixos" ]; then
      clear
      cat /etc/README-INSTALLER.txt
      echo ""
      echo "Quick commands:"
      echo "  WiFi:    nmtui"
      echo "  Install: sudo /etc/install-hermes.sh <your-repo-url>"
      echo ""
    fi
  '';

  # Increase console font size for easier reading
  console.font = "ter-v22b";
  console.packages = with pkgs; [terminus_font];

  # Pre-configure git for convenience
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "master";
    };
  };
}
