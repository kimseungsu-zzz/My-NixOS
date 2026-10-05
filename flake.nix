{
  description = "linux NixOS system";

  inputs = {
    # Matches system.stateVersion in configuration.nix.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Hancom Office 2020 (private repo, fetched with the `gh auth login` credentials like the other
    # private inputs). Only the package definition lives there; the installer is downloaded by the
    # build from a pinned URL. It brings its own nixpkgs pins (the app needs 19.09 libraries).
    hnc2020.url = "git+https://github.com/kimseungsu-zzz/nixos-HNC2020";

    # ChatGPT Community (unofficial Linux build of the ChatGPT/Codex desktop app). It keeps its
    # own nixpkgs pin on purpose: its derivation patches the official Electron payload.
    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    # Claude Desktop (official Linux beta from Anthropic's apt repo, packaged for Nix).
    claude-desktop.url = "github:poeck/claude-desktop-nix-flake";

    # Private monorepo: Fusion 360, Studica Hardware Manager, Titan Config, KakaoTalk, Karousel (packages + NixOS
    # modules). Fetched over HTTPS with the gh credentials, like the other private inputs.
    nix-packages = {
      url = "git+https://github.com/kimseungsu-zzz/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # KDE Plasma settings as code (home.nix, programs.plasma).
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, hnc2020, nix-packages, codex-desktop-linux, claude-desktop, home-manager, plasma-manager, ... }: {
    # nixos-rebuild switch --flake .#linux
    # `nixos` is an alias: nixos-rebuild looks up the *current* hostname.
    nixosConfigurations = rec {
      linux = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          codex-desktop-linux.nixosModules.default
          claude-desktop.nixosModules.default
          hnc2020.nixosModules.default
          nix-packages.nixosModules.fusion360
          nix-packages.nixosModules.studica-hardware-manager
          nix-packages.nixosModules.titan-config
          nix-packages.nixosModules.kakaotalk
          nix-packages.nixosModules.karousel
          nix-packages.nixosModules.legacylauncher
          nix-packages.nixosModules.zapret-gui
          { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # An existing plasma config file is moved aside instead of
              # aborting the first activation.
              backupFileExtension = "hm-backup";
              sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              users.linux = import ./home.nix;
            };
          }
        ];
      };
      nixos = linux;
    };
  };
}
