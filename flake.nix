{
  description = "kimseungsu NixOS system";

  inputs = {
    # Matches system.stateVersion in configuration.nix.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Hancom Office (private repo): 로컬 클론을 직접 참조한다. `git pull` 후
    # `nix flake update hnc` 로 갱신.
    hnc = {
      url = "git+file:///home/linux/github/nixos-hnc";
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

  outputs = { nixpkgs, hnc, home-manager, plasma-manager, ... }: {
    # nixos-rebuild switch --flake .#kimseungsu
    # `nixos` is an alias: nixos-rebuild looks up the *current* hostname.
    nixosConfigurations = rec {
      kimseungsu = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          hnc.nixosModules.default
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
      nixos = kimseungsu;
    };
  };
}
