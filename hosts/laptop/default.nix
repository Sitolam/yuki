{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  disabledModules = [
    # Disable the default Awesome WM module
    "services/x11/window-managers/awesome.nix"
  ];

  imports = [
    # Shared configuration across all machines
    ../shared

    # Select the user configuration
    ../shared/users/sitolam.nix

    # Specific configuration
    ./hardware-configuration.nix
  ];

  boot = {
    kernelModules = ["acpi_call"];
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    extraModulePackages = with config.boot.kernelPackages; [acpi_call];
    kernelParams = [
      "i8042.direct"
      "i8042.dumbkbd"
      "i915.force_probe=46a6"
    ];
    loader = {
  		timeout = 3;
  		grub = {
  			enable = true;
  			devices = ["nodev"];
  			efiSupport = true;
  			useOSProber = true;
  			configurationLimit = 5;
        gfxmodeEfi = "1920x1080";
        theme = pkgs.fetchzip {
          # https://github.com/AdisonCavani/distro-grub-themes
          url = "https://raw.githubusercontent.com/AdisonCavani/distro-grub-themes/master/themes/lenovo.tar";
          hash = "sha256-6ZevSnSNJ/Q67DTNJj8k4pjOjWZFj0tG0ljG3gwbLuc=";
          stripRoot = false;
        };
        default = "0";
        extraEntries = ''
          menuentry "Reboot" {
            reboot
          }
          menuentry "Poweroff" {
            halt
          };
        '';
  		};
  		efi = {
  			canTouchEfiVariables = true;
  			efiSysMountPoint = "/boot";
  		};
 	};
};
  environment = {
    variables = {
      GDK_SCALE = "2";
      GDK_DPI_SCALE = "0.5";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    systemPackages = with pkgs; [
      acpi
      cryptsetup
      libva
      libva-utils
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
    ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      package = pkgs.bluezFull;
    };

    nvidia = {
      modesetting.enable = true;

      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";

        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        reverseSync.enable = true;
      };
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
        vaapiIntel
        vaapiVdpau
        nvidia-vaapi-driver
      ];
    };
  };

  networking = {
  	defaultGateway = "192.168.68.1";
  	nameservers = [ 
  					"1.1.1.1"
  					"1.0.0.1"
  				  ];
  	hostName = "nixosbox";
  	useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  	interfaces = {
  		wlp59s0 = {
  			ipv4.addresses = [ {
  				address = "192.168.68.117";
  				prefixLength = 24;
  			}];
  		};
    };
};
  services = {
    acpid.enable = true;
    btrfs.autoScrub.enable = true;
    logind.lidSwitch = "suspend";
    thermald.enable = true;
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 0; # dummy value
        STOP_CHARGE_THRESH_BAT0 = 1; # battery conservation mode
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };

    upower.enable = true;

    xserver = {
      dpi = 144;
      libinput = {
        enable = true;
        touchpad = {naturalScrolling = true;};
      };

      xkbOptions = "caps:escape";
      videoDrivers = ["nvidia"];
    };
  };

  # Use custom Awesome WM module
  services.xserver.windowManager.awesome.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
