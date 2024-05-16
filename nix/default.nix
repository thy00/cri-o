{ system ? builtins.currentSystem }:

let
  static = import ./static.nix;
  json = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
  nixpkgs = import (builtins.fetchTarball {
    name = "nixos-unstable";
    url = "${json.url}/archive/${json.rev}.tar.gz";
    inherit (json) sha256;
  }) { inherit system; };

  pkgs = nixpkgs // {
    go = nixpkgs.go.overrideAttrs (oldAttrs: {
      doCheck = false; # Overriding go package to disable checks
    });
    # Apply static as described in static.nix
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