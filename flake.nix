{
  description = "kimseungsu NixOS system";

  inputs = {
    # Matches system.stateVersion in configuration.nix.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { nixpkgs, ... }: {
    # nixos-rebuild switch --flake .#kimseungsu
    # `nixos` is an alias: nixos-rebuild looks up the *current* hostname.
    nixosConfigurations = rec {
      kimseungsu = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }
        ];
      };
      nixos = kimseungsu;
    };
  };
}
