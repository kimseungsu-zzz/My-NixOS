# Catppuccin look for SDDM and the shared cursor theme.
#   flavor: latte | frappe | macchiato | mocha     accent: mauve | blue | pink | ...
{ pkgs, ... }:

let
  flavor = "mocha";
  accent = "mauve";
in
{
  environment.systemPackages = [
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
