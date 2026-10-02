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
  };

  outputs = { nixpkgs, hnc, ... }: {
    # nixos-rebuild switch --flake .#kimseungsu
    # `nixos` is an alias: nixos-rebuild looks up the *current* hostname.
    nixosConfigurations = rec {
      kimseungsu = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          hnc.nixosModules.default
          { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }
        ];
      };
      nixos = kimseungsu;
    };
  };
}
