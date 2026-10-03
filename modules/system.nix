{ ... }:

{
  # Bootloader. Keep only the latest generations in the boot menu; older ones
  # are removed from /boot on the next switch (and from the store by nix.gc).
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "linux";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Seoul";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users."linux" = {
    isNormalUser = true;
    description = "Linux";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  services.openssh.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Automatic cleanup of old build results: every week, delete generations and
  # store paths older than 7 days (the running generation is always kept),
  # and hard-link identical files in the store.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

  # Do not change after install; see `man configuration.nix`.
  system.stateVersion = "26.05";
}
