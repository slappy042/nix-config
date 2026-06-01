{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "z13ctl";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "dahui";
    repo = "z13ctl";
    rev = "v${version}";
    hash = "sha256-21mdAzbw8JISDLG7iSEI4VCephDTtbioN0/RRxvCLR8=";
  };

  vendorHash = "sha256-ftkcianIR36PNAoMOVuk4lUr7goWUcHhjyNseUraJU0=";

  # ./api is a separate nested Go module (replace directive); don't build it as a subpackage
  subPackages = [ "." ];

  meta = with lib; {
    description = "Control utility for the 2025 ASUS ROG Flow Z13 laptop";
    homepage = "https://github.com/dahui/z13ctl";
    license = licenses.asl20;
    mainProgram = "z13ctl";
  };
}
