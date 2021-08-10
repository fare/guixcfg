;; Jackhill: https://paste.debian.net/1206838/

(use-modules
  (gnu)
  (gnu packages fonts) (gnu packages fontutils) (gnu packages ghostscript) (gnu packages lisp)
  (gnu packages screen) (gnu packages shells) (gnu packages tex) (gnu packages xorg)
  (gnu services dbus) (gnu services nix) (gnu system nss)
  (guix channels) (guix inferior) (guix modules)
  (nongnu packages fonts) (nongnu packages linux) (nongnu system linux-initrd)
  (srfi srfi-1))

(use-service-modules
  desktop ssh xorg virtualization);; docker

(use-package-modules
  admin certs gnome linux vpn wm
  package-management ssh tls)

(operating-system
  (host-name "yew")
  (timezone "America/New_York")
  (locale "en_US.UTF-8")

  ;; BEWARE: Guix does not support a separate /boot partition yet http://issues.guix.gnu.org/48172
  ;;; (bootloader (bootloader-configuration (bootloader grub-bootloader) (target "/dev/nvme0n1")))
  ;; So instead, we'll generate a grub configuration and we'll integrate it into the grub from NixOS
  ;; with the guix-boot.ss script (written in Gerbil Scheme).
  ;; From http://guix.gnu.org/en/cookbook/en/html_node/Running-Guix-on-a-Linode-Server.html --
  ;; This goofy code will generate the grub.cfg without installing the grub bootloader on disk.
  (bootloader
    (bootloader-configuration
      (bootloader
        (bootloader
          (inherit grub-bootloader)
          (installer #~(const #true))))
      #;(target "/boot/guix") ;;; Won't work, because grub won't find it as a device
      ))

  (mapped-devices
    (list
      (mapped-device
        (source (uuid "6761c21c-1188-4955-9109-3efb088efc05"))
        (target "yew.crypt")
        (type luks-device-mapping))
      (mapped-device
        (source "yew")
        (targets (list "yew-home" "yew-nixos" "yew-guix"))
        (type lvm-device-mapping))))

  (file-systems
    (append
     (let* ((boot (file-system
                   ;;(uuid "C1D9-0574")
                   (device "/dev/nvme0n1p1")
                   (mount-point "/boot")
                   (flags '(lazy-time))
                   (type "vfat")))
            (root (file-system
                   ;;(device "/dev/mapper/yew-guix")
                   (device (uuid "43f7ca3e-c107-4f15-9756-5d3cbacad0a0"))
                   (mount-point "/")
                   (type "btrfs")
                   (flags '(lazy-time))
                   (options "compress=zstd")
                   (dependencies mapped-devices)))
            (home (file-system
                   ;;(device "/dev/yew/home")
                   (device (uuid "a3602532-3527-4afc-9b40-5d01c58b5aa8"))
                   (mount-point "/home")
                   (type "ext4")
                   (flags '(lazy-time))
                   (dependencies mapped-devices)))
            (nixos (file-system
                    (device (uuid "ab3d691b-227a-4a05-a084-6928abbf0959"))
                    (mount-point "/nixos")
                    (type "ext4")
                    (flags '(lazy-time))
                    (dependencies mapped-devices)))
            (nix (file-system ;; see https://issues.guix.gnu.org/issue/35472
                  (device "/nixos/nix")
                  (mount-point "/nix")
                  (type "none")
                  (flags '(bind-mount lazy-time))
                  (dependencies (list nixos)))))
       (cons* boot root home nixos nix %base-file-systems))))

  (swap-devices (list (uuid "1a3915f9-c00c-4e62-ab7d-d6d7a2641e4d"))) ;; "/dev/yew/swap"

  (kernel linux)
  (kernel-arguments
    '("quite"
      "zswap.enabled=1" "zswap.compressor=zstd"
      "zswap.max_pool_percent=50" "zswap.zpool=z3fold"))
  (initrd-modules
    (cons*
      "zstd" "z3fold"
      "video" "i915"

      "snd-pcm-oss" "snd-mixer-oss" ;; somehow don't get autoloaded but mplayer wants it by default

      ;;"ahci" "usbhid"
      ;;"ccm" "xts" "arc4"
      ;;"coretemp" "psmouse" "fuse" "cryptd"
      ;;"r8169" "mmc_block" "sdhci" "sdhci_pci" "rtsx_pci_sdmmc"

      ;; "virtio" "virtio_scsi"
      ;; "kvm-intel" "kvm-amd" "ehci_hcd" "usb_storage" "ext4" "vfat" "ctr" "tun"
      ;; "dm_crypt" "aes_generic" "sha256_generic"
      ;; "cbc" "dm_mod" "ecb" "sd_mod" "snd_hda_intel" "uhci_hcd" "mmc_core" "nvme"
      %base-initrd-modules))

  (initrd microcode-initrd)
  (firmware
    (cons* linux-firmware iwlwifi-firmware broadcom-bt-firmware %base-firmware))

  (users
   (append
    (list
     (user-account
      (name "fare")
      (comment "Francois-Rene Rideau")
      (group "users")
      (shell (file-append zsh "/bin/zsh"))
      ;; Adding the account to the "wheel" group makes it a sudoer.
      (supplementary-groups '("wheel" "audio" "video" "netdev" "dialout")) ; "adbusers"
      (home-directory "/home/fare")))
    %base-user-accounts))

  (sudoers-file (plain-file "sudoers"
                            "root ALL=(ALL:ALL) SETENV: ALL
%wheel ALL=(ALL:ALL) NOPASSWD:SETENV: ALL"))

  (keyboard-layout (keyboard-layout "us"))

  (packages
    (append
     (map specification->package
          '("nss-certs" "openssh" "lvm2" "btrfs-progs" "e2fsprogs"
            "screen" "zsh" "rlwrap"))
     %base-packages))

  (services
    (cons*
      (set-xorg-configuration
        (xorg-configuration
          #;(server-arguments '()) ;; disable the default '("-nolisten" "tcp") ;--- don't do it until we have a good firewall!
          (keyboard-layout keyboard-layout)
          (extra-config '()))) ;;TODO: set the device resolution
      (service gpm-service-type)
      (service nix-service-type
        (nix-configuration
          (extra-config
           '("substituters = https://cache.nixos.org https://cache.nixos.org/ https://hydra.iohk.io https://iohk.cachix.org https://mukn.cachix.org"
             "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo= hydra.goguen-ala-cardano.dev-mantis.iohkdev.io-1:wh2Nepc/RGAY2UMvY5ugsT8JOz84BKLIpFbn7beZ/mo= mukn.cachix.org-1:ujoZLZMpGNQMeZbLBxmOcO7aj+7E5XSnZxwFpuhhsqs="))))
      (service openssh-service-type
        (openssh-configuration
          (openssh openssh)
          (x11-forwarding? #t)
          (password-authentication? #false)
          (authorized-keys
            `(("fare" ,(local-file "/home/fare/.ssh/id_rsa.pub"))
              ("root" ,(local-file "/home/fare/.ssh/id_rsa.pub"))))))
      (pam-limits-service
        (list
          (pam-limits-entry "@audio" 'both 'rtprio 99)
          (pam-limits-entry "@audio" 'both 'memlock 'unlimited)))
      #;(service libvirt-service-type (libvirt-configuration (unix-sock-group "libvirt") (tls-port "16555")))
      #;(service virtlog-service-type (virtlog-configuration (max-clients 1000)))
      #;(service singularity-service-type)
      #;(service docker-service-type)

      (modify-services %desktop-services
        (console-font-service-type _config =>
          (map (lambda (i)
                 (cons (format #f "tty~d" i) "Lat15-TerminusBold32x16"))
               (iota 6 1)))
        (guix-service-type config =>
          (guix-configuration
            (inherit config)
            #;(substitute-urls (cons* "http://guix.drewc.ca:8080/" %default-substitute-urls))
            #;(authorized-keys (cons* (local-file "./druix-key.pub") %default-authorized-guix-keys)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
