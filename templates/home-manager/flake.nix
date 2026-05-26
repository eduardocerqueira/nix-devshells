{
  description = "Home Manager template for nix-devshells";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      # ============================================================================
      # USER CONFIGURATION — update these values
      # ============================================================================
      username = "YOUR_USER";
      homeDirectory = "/Users/YOUR_USER";
      nixDevshellsPath = "/Users/YOUR_USER/git/eduardo/nix-devshells";
      gitName = "Your Name";
      gitEmail = "you@example.com";
      # ============================================================================
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = {
          inherit username homeDirectory nixDevshellsPath gitName gitEmail;
        };
      };
    };
}
