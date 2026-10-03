{
  description = "linux NixOS system";

  inputs = {
    # Matches system.stateVersion in configuration.nix.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Hancom Office (private repo): fetched over HTTPS with the git credentials
    # from `gh auth login` (port 22 is blocked on this network). Update with
    # `nix flake update hnc`.
    hnc = {
      url = "git+https://github.com/kimseungsu-zzz/nixos-hnc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Autodesk Fusion 360 (FHS + Wine + cryinkfly installer). Untested draft.
    fusion360 = {
      url = "github:kimseungsu-zzz/fusion360-nixos";
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

  outputs = { nixpkgs, hnc, fusion360, home-manager, plasma-manager, ... }: {
    # nixos-rebuild switch --flake .#linux
    # `nixos` is an alias: nixos-rebuild looks up the *current* hostname.
    nixosConfigurations = rec {
      linux = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          hnc.nixosModules.default
          fusion360.nixosModules.default
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
