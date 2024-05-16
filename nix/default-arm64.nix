let
  static = import ./static.nix;

  # 加载 nixpkgs 文件配置，这里需要引入系统参数
  json = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
  nixpkgs = import (builtins.fetchTarball {
    name = "nixos-unstable-arm64";
    url = "${json.url}/archive/${json.rev}.tar.gz";
    inherit (json) sha256;
  }) {
    system = "aarch64-linux"; 
  };

  pkgs = nixpkgs // {
    go = nixpkgs.go.overrideAttrs (oldAttrs: {
      doCheck = false; # 关闭 Go 包的检查阶段
    });
    gpgme = (static nixpkgs.gpgme);
    libassuan = (static nixpkgs.libassuan);
    libgpgerror = (static nixpkgs.libgpgerror);
    libseccomp = (static nixpkgs.libseccomp);
    gnupg = nixpkgs.gnupg.override {
      libusb1 = null;
      pcsclite = null;
    };
  };

  self = import ./derivation.nix { inherit pkgs; };
in
self // {
  # Debug output for verification in Nix REPL
  goDoCheck = nixpkgs.lib.traceVal pkgs.go.doCheck;
}