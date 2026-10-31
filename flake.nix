{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.throw-away = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ({ pkgs, ... }: {
          system.stateVersion = "25.05";
          boot.loader.systemd-boot.enable = true;

          # Sway (Wayland tiling WM)
          programs.sway = {
            enable = true;
            wrapperFeatures.gtk = true;
          };
          security.polkit.enable = true;
          security.rtkit.enable = true;

          programs.firefox.enable = true;

          # ProtonVPN's GUI talks to NetworkManager for the WireGuard/OpenVPN tunnels
          networking.networkmanager.enable = true;
          environment.systemPackages = [ pkgs.protonvpn-gui ];

          users.users.user = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" ];
          initialPassword = "changeme";
          };
        })
      ];
    };
  };
}
