{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      astal,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = astal.lib.mkLuaPackage {
        inherit pkgs;
        name = "pidgets";
        src = ./app;

        extraPackages =
          with astal.packages.${system};
          [
            battery
            network
          ]
          ++ (with pkgs; [
            dart-sass
            brightnessctl
            libgtop
          ]);
      };
    };
}
