{ pkgs, ... }:

let
  niriKakaoWindowSizeGuard = pkgs.writeShellApplication {
    name = "niri-kakao-window-size-guard";
    runtimeInputs = [ pkgs.niri pkgs.python3 ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./niri-kakao-window-size-guard.py}
    '';
  };

in
{
  # User-level GUI applications.
  home.packages = with pkgs; [
    kdePackages.kate
    vscode
    brave
    spotify
    vlc
    kicad
    vicinae
    eww
    alsa-utils
    brightnessctl
    ffmpeg
    mpc
    networkmanagerapplet
    wireplumber
  ];

  systemd.user.services.niri-kakao-window-size-guard = {
    Unit = {
      Description = "Correct oversized KakaoTalk windows once after opening";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${niriKakaoWindowSizeGuard}/bin/niri-kakao-window-size-guard";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
