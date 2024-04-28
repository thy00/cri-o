{ system ? builtins.currentSystem }:
let
  pkgs = import ./nixpkgs.nix {
    config = {
      packageOverrides = pkg: {
        go_1_12 = pkg.go_1_15;
      };
    };
  };

  static = pkg: pkg.overrideAttrs(old: {
    configureFlags = (old.configureFlags or []) ++
      [ "--without-shared" "--disable-shared" ];
    dontDisableStatic = true;
    enableSharedExecutables = false;
    enableStatic = true;
  });

  patchLvm2 = pkg: pkg.overrideAttrs(old: {
    configureFlags = [
      "--disable-cmdlib" "--disable-readline" "--disable-udev_rules"
      "--disable-udev_sync" "--enable-pkgconfig" "--enable-static_link"
    ];
    preConfigure = old.preConfigure + ''
      substituteInPlace libdm/Makefile.in --replace \
        SUBDIRS=dm-tools SUBDIRS=
      substituteInPlace tools/Makefile.in --replace \
        "TARGETS += lvm.static" ""
      substituteInPlace tools/Makefile.in --replace \
        "INSTALL_LVM_TARGETS += install_tools_static" ""
    '';
    postInstall = "";
  });

  self = {
    cri-o-static = (pkgs.cri-o.overrideAttrs(old: {
      name = "cri-o-static";
      buildInputs = old.buildInputs ++ (with pkgs; [ systemd ]);
      src = ./..;
      buildPhase = ''
        pushd go/src/github.com/cri-o/cri-o
        make BUILDTAGS="apparmor seccomp selinux containers_image_ostree_stub netgo" \
          bin/crio \
          bin/crio-status \
          bin/pinns
      '';
      EXTRA_LDFLAGS = ''-linkmode external -extldflags "-static -lm"'';
      dontStrip = true;
      # DEBUG = 1; # Uncomment this line to enable debug symbols in the binary
    })).override {
      flavor = "-static";
      gpgme = (static pkgs.gpgme);
      libassuan = (static pkgs.libassuan);
      libgpgerror = (static pkgs.libgpgerror);
      libseccomp = (static pkgs.libseccomp);
      lvm2 = (patchLvm2 (static pkgs.lvm2));
    };
  };
in self
