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

          # Only applied while the account has no password set - won't overwrite
          # one you later set with `passwd`. Change it after the first login.
          users.users.user = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" "video" ];
            initialPassword = "changeme";
          };

          programs.firefox.enable = true;

          # ProtonVPN's GUI talks to NetworkManager for the WireGuard/OpenVPN tunnels
          networking.networkmanager.enable = true;
          environment.systemPackages = [ pkgs.protonvpn-gui pkgs.foot pkgs.i3status ];


          # --- Login manager (greetd + tuigreet) ---
          # Minimal privileged daemon; the TUI greeter runs unprivileged as
          # "greeter" and launches the sway session configured below.
          services.greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
              user = "greeter";
            };
          };

          # polkit: NetworkManager enables it transitively, but keep it explicit
          # so blueman/pavucontrol auth prompts survive dropping NetworkManager.
          security.polkit.enable = true;

          # --- Sway ---
          # No 3D acceleration in the VM, so draw with pixman (plain 2D CPU
          # renderer) instead of letting Mesa emulate OpenGL.
          programs.sway = {
            enable = true;
            wrapperFeatures.gtk = true;
            # extraPackages left at the default on purpose: it brings wmenu,
            # swaylock and grim, which is why there's no rofi here.
            extraSessionCommands = ''
              export WLR_RENDERER=pixman
              export QT_QPA_PLATFORM="wayland;xcb"
              export SDL_VIDEODRIVER=wayland
              export ELECTRON_OZONE_PLATFORM_HINT=auto
            '';
          };

          # sway reads /etc/sway/config when the user has none of their own;
          # the sway module's own entry here is a mkOptionDefault, so this wins.
          environment.etc."sway/config".text = ''
            # -------- Variables -------------------------
            set $terminal foot
            set $menu wmenu-run
            # VM-friendly: SUPER is usually grabbed by the host OS, so use CTRL+ALT.
            # (CTRL+ALT+F1..F12 is the VT switch, so don't bind plain F-keys to it.)
            set $mod Ctrl+Mod1

            # -------- Look ------------------------------
            output * bg #000000 solid_color
            default_border pixel 2
            default_floating_border pixel 2
            gaps inner 4
            # class                 border  backgr. text    indicator child_border
            client.focused          #2b7bff #2b7bff #000000 #2b7bff   #2b7bff
            client.focused_inactive #0a1f3d #0a1f3d #2b7bff #0a1f3d   #0a1f3d
            client.unfocused        #0a1f3d #0a1f3d #2b7bff #0a1f3d   #0a1f3d

            # -------- Input -----------------------------
            input type:keyboard {
                xkb_layout us,fi
                # Both Ctrl keys together switch us/fi.
                xkb_options grp:ctrls_toggle
                repeat_rate 50
                repeat_delay 300
                xkb_numlock enabled
            }
            input type:touchpad {
                tap enabled
                natural_scroll disabled
                middle_emulation enabled
                dwt enabled
            }
            focus_follows_mouse yes
            workspace_auto_back_and_forth yes
            # Hold Alt: left-drag moves a window, right-drag resizes it.
            floating_modifier Mod1 normal

            # -------- Focus / move / resize -------------
            bindsym $mod+h focus left
            bindsym $mod+j focus down
            bindsym $mod+k focus up
            bindsym $mod+l focus right

            bindsym Mod1+h move left
            bindsym Mod1+l move right
            bindsym Mod1+k move up
            bindsym Mod1+j move down

            bindsym $mod+Tab focus next
            bindsym $mod+a focus prev

            bindsym $mod+Shift+h resize shrink width 70px
            bindsym $mod+Shift+l resize grow width 70px
            bindsym $mod+Shift+j resize grow height 70px
            bindsym $mod+Shift+k resize shrink height 70px

            bindsym $mod+Shift+F1 layout tabbed
            bindsym $mod+Shift+F2 layout default
            # Ctrl+Alt+s before opening a window: the new window is paired with the
            # focused one instead of joining the row (switches between side by side and
            # stacked; press it again to switch back).
            bindsym $mod+s split toggle
            # Alt+Tab: flip the split of the focused window's container. When it holds
            # just the pair, the two swap between side by side and stacked.
            bindsym Mod1+Tab layout toggle split

            # -------- General applications --------------
            bindsym $mod+n exec $terminal
            bindsym $mod+q kill
            bindsym $mod+Shift+q exit
            bindsym $mod+r exec $menu
            bindsym $mod+f exec firefox
            bindsym $mod+Shift+f exec firefox --private-window
            bindsym $mod+b exec blueman-manager

            # -------- Workspaces ------------------------
            bindsym $mod+1 workspace number 1
            bindsym $mod+2 workspace number 2
            bindsym $mod+3 workspace number 3
            bindsym $mod+4 workspace number 4
            bindsym $mod+5 workspace number 5
            bindsym $mod+6 workspace number 6
            bindsym $mod+7 workspace number 7
            bindsym $mod+8 workspace number 8
            bindsym $mod+9 workspace number 9
            bindsym $mod+0 workspace number 10
            bindsym $mod+Shift+1 move container to workspace number 1
            bindsym $mod+Shift+2 move container to workspace number 2
            bindsym $mod+Shift+3 move container to workspace number 3
            bindsym $mod+Shift+4 move container to workspace number 4
            bindsym $mod+Shift+5 move container to workspace number 5
            bindsym $mod+Shift+6 move container to workspace number 6
            bindsym $mod+Shift+7 move container to workspace number 7
            bindsym $mod+Shift+8 move container to workspace number 8
            bindsym $mod+Shift+9 move container to workspace number 9
            bindsym $mod+Shift+0 move container to workspace number 10

            # mouse wheel over any window
            bindsym --whole-window $mod+button5 workspace next_on_output
            bindsym --whole-window $mod+button4 workspace prev_on_output

            # -------- Volume ----------------------------
            bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
            bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
            bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            bindsym --locked XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

            # -------- Window rules ----------------------
            for_window [app_id="^(blueman-manager|nm-connection-editor|pavucontrol|org.pulseaudio.pavucontrol|xdg-desktop-portal-gtk)$"] floating enable, resize set 70 ppt 70 ppt
            for_window [title="^Authentication Required$"] floating enable
            for_window [title="^(Open Files?|Save As|Open Folder)"] floating enable, resize set 70 ppt 60 ppt
            for_window [title="^Picture-in-Picture$"] floating enable, sticky enable

            # -------- Bar -------------------------------
            # swaybar; it has no tray, so no applets are started below.
            bar {
                position top
                font "monospace 10"
                status_command i3status
                colors {
                    background #000000
                    statusline #2b7bff
                    focused_workspace  #2b7bff #2b7bff #000000
                    inactive_workspace #000000 #000000 #2b7bff
                }
            }

            # -------- Autostart -------------------------
            exec $terminal
          '';

          # i3status reads this when the user has no ~/.config/i3status/config.
          environment.etc."i3status.conf".text = ''
            general {
                colors = true
                interval = 5
                output_format = "i3bar"
            }

            order += "wireless _first_"
            order += "volume master"
            order += "battery 0"
            order += "tztime local"

            wireless _first_ {
                format_up = "W: %essid %quality"
                format_down = "W: down"
            }

            volume master {
                format = "vol %volume"
                format_muted = "vol muted"
            }

            battery 0 {
                format = "%status %percentage"
            }

            tztime local {
                format = "%Y-%m-%d %H:%M"
            }
          '';

          # --- Audio (PipeWire) ---
          # Needed both for the wpctl volume binds and for Bluetooth A2DP.
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;
          };

          # --- Bluetooth ---
          # blueman-manager runs standalone (bound to $mod+b); the tray applet
          # would be invisible since swaybar has no tray.
          hardware.bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
          services.blueman.enable = true;
        })
      ];
    };
  };
}
