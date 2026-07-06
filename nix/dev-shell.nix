{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {

  buildInputs = with pkgs; [

    flutter344

    cmake
    clang

    pkg-config
    gtk3
    libsysprof-capture
    pcre2
    util-linux
    libselinux
    libsepol
    libthai
    libdatrie
    libXdmcp
    lerc
    libxkbcommon
    libepoxy
    libXtst

  ];

}
