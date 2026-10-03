{ ... }:

{
  home.stateVersion = "26.05";

  programs.plasma = {
    enable = true;

    # false: settings listed here are enforced on every login, everything else
    # is left as the GUI set it. Switch to true once this file describes the
    # whole desktop; then anything not listed is reset to default on activation.
    overrideConfig = false;

    # Paste the output of `nix run github:nix-community/plasma-manager` here
    # (it prints your current Plasma settings as Nix), then trim it down.
    # Higher-level options: https://nix-community.github.io/plasma-manager/options.html
    #
    # workspace = { ... };   # theme, cursor, icons, wallpaper
    # panels = [ ... ];      # panel layout and widgets
    # shortcuts = { ... };   # keyboard shortcuts
    # input.keyboard = { ... };
  };
}
