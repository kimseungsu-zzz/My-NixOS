{
  description = "kimseungsu NixOS system, plus WPILib (VMX 2020 build) packaged for Nix";

  inputs = {
    # Matches system.stateVersion in configuration.nix.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # payload/ is gitignored, and a git-tracked flake cannot see ignored files,
    # so it is taken as a plain path input. Point it elsewhere with
    #   --override-input payload path:/abs/path/to/payload
    # and refresh the lock with `nix flake update payload` after changing it.
    payload = {
      url = "path:./payload";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, payload }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # vscode
      };
      inherit (pkgs) lib;

      # Mirrors scripts/versions.gradle and scripts/vscode.gradle.
      year = "2020_vmx";
      wpilibExtVersion = "2020.3.2";
      gradleVersion = "6.0.1";
      # MD5 of the distribution URL in base 36; the same value gradlew.gradle
      # computes, and the directory the Gradle wrapper looks in.
      gradleDistHash = "1lxlpkiy24sb18odw96cp4ojv";

      # Gradle 6.0.1 cannot run on anything newer than JDK 13. The Gradle
      # build uses a dropped-in AdoptOpenJDK 11 instead of payload/jdk.
      jdk = pkgs.jdk11;

      # vscode-wpilib hardcodes the year it looks for; patched the same way
      # scripts/vscode.gradle does it.
      wpilibExt = pkgs.stdenvNoCC.mkDerivation {
        pname = "vscode-wpilib";
        version = wpilibExtVersion;
        src = pkgs.fetchurl {
          url = "https://github.com/wpilibsuite/vscode-wpilib/releases/download/v${wpilibExtVersion}/vscode-wpilib-${wpilibExtVersion}.vsix";
          name = "vscode-wpilib-${wpilibExtVersion}.zip";
          hash = "sha256-Whxogf+i3iQMaYfBbhA1m7rVVQ2ia46qMJlKCw3f7Oo=";
        };
        nativeBuildInputs = [ pkgs.unzip ];
        sourceRoot = ".";
        installPhase = ''
          d=$out/share/vscode/extensions/wpilibsuite.vscode-wpilib
          mkdir -p $d
          cp -r extension/. $d/
          chmod -R u+w $d
          substituteInPlace $d/out/extension.js \
            --replace-fail 'getFrcYear(){return"2020"}' 'getFrcYear(){return"${year}"}'
          substituteInPlace $d/resources/gradle/shared/settings.gradle \
            --replace-fail "String frcYear = '2020'" "String frcYear = '${year}'"
        '';
        passthru = {
          vscodeExtPublisher = "wpilibsuite";
          vscodeExtName = "vscode-wpilib";
          vscodeExtUniqueId = "wpilibsuite.vscode-wpilib";
        };
      };

      # The installer pins cpptools 0.26.2; nixpkgs ships a patched, newer one.
      vscodeWithExt = pkgs.vscode-with-extensions.override {
        vscodeExtensions = [
          pkgs.vscode-extensions.ms-vscode.cpptools
          wpilibExt
        ];
      };

      gradleDist = pkgs.fetchzip {
        url = "https://services.gradle.org/distributions/gradle-${gradleVersion}-bin.zip";
        hash = lib.fakeHash; # run `nix build` once and paste the reported hash
      };

      # payload/ holds the toolchains, desktop tools and maven repositories.
      # Native binaries in it (cross compilers) are ELF-patched so they run
      # without nix-ld.
      tree = pkgs.stdenv.mkDerivation {
        name = "wpilib-${year}-payload";
        src = payload;
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          ncurses5
          expat
          xz
          libxcrypt-legacy
        ];
        # Bundled tools may carry libraries that autoPatchelf cannot place
        # (optional GUI libraries); a failing build is worse than a missing one.
        autoPatchelfIgnoreMissingDeps = true;
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          for d in toolchains tools vendordeps documentation; do
            if [ -d "$d" ]; then cp -r "$d" $out/; fi
          done
          mkdir -p $out/maven
          for d in maven/wpilib maven/vendor; do
            if [ -d "$d" ]; then cp -rn "$d"/. $out/maven/; fi
          done
          chmod -R u+w $out
        '';
      };

      # What the installer lays down at ~/wpilib/<year>.
      home = pkgs.runCommand "wpilib-${year}-home" { } ''
        d=$out/share/wpilib/${year}
        mkdir -p $d
        ln -s ${jdk.home} $d/jdk
        for x in maven tools vendordeps documentation toolchains; do
          if [ -e ${tree}/$x ]; then ln -s ${tree}/$x $d/$x; fi
        done
      '';

      launcher = pkgs.runCommand "wpilibcode-${year}" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        makeWrapper ${vscodeWithExt}/bin/code $out/bin/wpilibcode${year} \
          --set JAVA_HOME ${jdk.home} \
          --prefix PATH : ${jdk}/bin
      '';

      # Everything that has to live in writable user state rather than the store:
      # the ~/wpilib entry, GradleRIO's toolchain lookup, the offline-maven init
      # script (postInstall/postinstall.sh) and the pre-extracted Gradle wrapper
      # distribution (the installer's gradleConfig step).
      setup = pkgs.writeShellScriptBin "wpilib-setup-${year}" ''
        set -euo pipefail
        install_dir="$HOME/wpilib/${year}"
        gradle_home="''${GRADLE_USER_HOME:-$HOME/.gradle}"

        mkdir -p "$HOME/wpilib"
        ln -sfn ${home}/share/wpilib/${year} "$install_dir"

        mkdir -p "$gradle_home/toolchains" "$gradle_home/init.d"
        if [ -d ${tree}/toolchains ]; then
          cp -rsn ${tree}/toolchains/. "$gradle_home/toolchains/"
        fi

        sed "s|@INSTALL_DIR@|$install_dir|g" ${self}/postInstall/wpilib-init.gradle \
          > "$gradle_home/init.d/wpilib-vmx.gradle"

        dist="$gradle_home/wrapper/dists/gradle-${gradleVersion}-bin/${gradleDistHash}"
        if [ ! -e "$dist/gradle-${gradleVersion}-bin.zip.ok" ]; then
          mkdir -p "$dist"
          cp -rL --no-preserve=mode,ownership ${gradleDist} "$dist/gradle-${gradleVersion}"
          chmod +x "$dist/gradle-${gradleVersion}/bin/gradle"
          touch "$dist/gradle-${gradleVersion}-bin.zip.ok"
        fi

        echo "WPILib ${year} linked at $install_dir"
      '';

      wpilib = pkgs.symlinkJoin {
        name = "wpilib-${year}";
        paths = [ home launcher setup ];
        passthru = { inherit tree wpilibExt vscodeWithExt jdk; };
      };
    in
    {
      packages.${system} = {
        default = wpilib;
        inherit wpilib wpilibExt;
      };

      apps.${system}.default = {
        type = "app";
        program = "${launcher}/bin/wpilibcode${year}";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ jdk launcher setup ];
        JAVA_HOME = jdk.home;
      };

      # nixos-rebuild switch --flake .#kimseungsu
      # `nixos` is an alias: nixos-rebuild looks up the *current* hostname,
      # which is still "nixos" until the first switch applies kimseungsu.
      nixosConfigurations = rec {
        kimseungsu = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              # Enable once the two lib.fakeHash values above are filled in
              # (`nix build .#wpilib` reports them); until then the system
              # build would fail on the hash mismatch.
              # environment.systemPackages = [ wpilib ];
            }
          ];
        };
        nixos = kimseungsu;
      };
    };
}
