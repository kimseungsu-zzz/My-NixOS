# Catppuccin look for Plasma, applied from home/plasma.nix (workspace.*).
# Change flavor/accent here and in home/plasma.nix together (names must match).
#   flavor: latte | frappe | macchiato | mocha     accent: mauve | blue | pink | ...
{ pkgs, ... }:

let
  flavor = "mocha";
  accent = "mauve";
in
{
  environment.systemPackages = [
    # Plasma colour scheme, global theme (Look and Feel), Aurorae window decorations.
    (pkgs.catppuccin-kde.override {
      flavour = [ flavor ];
      accents = [ accent ];
      winDecStyles = [ "modern" ];
    })
    # Papirus icons with Catppuccin folder colours (theme names Papirus, Papirus-Dark, ...).
    (pkgs.catppuccin-papirus-folders.override { inherit flavor accent; })
    # Cursor theme "catppuccin-mocha-mauve-cursors".
    pkgs.catppuccin-cursors.mochaMauve
    # Login screen theme "catppuccin-mocha-mauve".
    (pkgs.catppuccin-sddm.override {
      inherit flavor accent;
      font = "Pretendard";
      fontSize = "10";
    })
  ];

  fonts = {
    packages = with pkgs; [
      pretendard
      noto-fonts-cjk-sans
      nerd-fonts.jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Pretendard" "Noto Sans CJK KR" ];
      monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK KR" ];
    };
  };

  services.displayManager.sddm = {
    theme = "catppuccin-${flavor}-${accent}";
    extraPackages = [ pkgs.kdePackages.qtsvg ];
  };
}
