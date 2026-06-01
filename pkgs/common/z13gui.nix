{
  lib,
  buildGoModule,
  fetchFromGitHub,
  gtk4,
  gtk4-layer-shell,
  pkg-config,
  gobject-introspection,
  wrapGAppsHook4,
}:

buildGoModule rec {
  pname = "z13gui";
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "dahui";
    repo = "z13gui";
    rev = "v${version}";
    hash = "sha256-/o020uxesCNJIVeBbTncyJ5HF4huhj70X7TV+RZxnu4=";
  };

  vendorHash = "sha256-kIlz6P9IWaBF6Q0LwNILq0VvbVM9/SOIMdTo+7li7FA=";

  nativeBuildInputs = [
    pkg-config
    gobject-introspection
    wrapGAppsHook4
  ];
  buildInputs = [
    gtk4
    gtk4-layer-shell
  ];

  meta = with lib; {
    description = "GTK4 overlay interface for z13ctl on the 2025 ASUS ROG Flow Z13";
    homepage = "https://github.com/dahui/z13gui";
    license = licenses.asl20;
    mainProgram = "z13gui";
  };
}
