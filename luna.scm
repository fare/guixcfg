;; Main (NON)GUIX configuration for luna, a Lenovo Thinkpad X1 Extreme Gen 5
;; # dmidecode -s system-version
;; ThinkPad X1 Extreme Gen 5
;; See https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Extreme_(Gen_5)
;; TODO: In BIOS under Security > I/O Port Access and disable the Thunderbolt 4 also go to Config > Power > Sleep state, and set to Linux S3. Also some thread about this issue on Lenovo forums. 


(use-modules
  (gnu)
  (gnu packages cups) (gnu packages fonts) (gnu packages fontutils)
  (gnu packages ghostscript) (gnu packages lisp)
  (gnu packages screen) (gnu packages shells) (gnu packages tex) (gnu packages xorg)
  (gnu services cups) (gnu services dbus) (gnu services nix) (gnu services sound)
  (gnu system nss)
  (guix channels) (guix inferior) (guix modules)
  (nongnu packages fonts) (nongnu packages linux) (nongnu system linux-initrd)
  (srfi srfi-1))

(use-service-modules
  desktop ssh xorg virtualization);; docker

(use-package-modules
  admin certs gnome linux vpn wm
  package-management ssh tls)

(operating-system
  (host-name "luna")
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
          (inherit grub-efi-bootloader)
          #;(installer #~(const #true)))) ;; "/dev/nvme0n1" "(hd0)"
      (targets '("/boot"))))

  (mapped-devices
    (list
      (mapped-device
        (source (uuid "d825f838-477e-4dab-bc81-35b7955f08a7"))
        (target "luna.crypt")
        (type luks-device-mapping))
      (mapped-device
        (source "luna")
        (targets (list "luna-swap" "luna-root"))
        (type lvm-device-mapping))))

  (file-systems
    (append
     (let* ((root (file-system
                   (device "/dev/mapper/luna-root")
                   (mount-point "/")
                   (type "btrfs")
                   (flags '(lazy-time))
                   (options "compress=zstd")
                   (dependencies mapped-devices)))
            (boot (file-system
                   ;;(uuid "F01D-F88C")
                   (device "/dev/nvme0n1p1")
                   (mount-point "/boot")
                   (flags '(lazy-time))
                   (type "vfat"))))
       (cons* root boot %base-file-systems))))

  (swap-devices
   (list
    (swap-space
     (target "/dev/luna/swap")
     (discard? #t)
     (dependencies mapped-devices))))

  (kernel linux)
  (kernel-arguments
   '(;;"quite" ;; what is that? quiet? Where from?
     "ibt=off" ;; Video related says the ArchLinux page
     "zswap.enabled=1" "zswap.compressor=zstd"
     "zswap.max_pool_percent=50" "zswap.zpool=z3fold"))
  (initrd-modules
    (cons*
      "zstd" "z3fold"
      "video" "i915"
      ;;"snd-pcm-oss" "snd-mixer-oss" ;; somehow don't get autoloaded but mplayer wants it by default
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
      (supplementary-groups '("wheel" "audio" "video" "netdev" "dialout" "lp" "kvm")) ; "adbusers"
      (home-directory "/home/fare")))
    %base-user-accounts))

  (sudoers-file (plain-file "sudoers"
                            "root ALL=(ALL:ALL) SETENV: ALL
%wheel ALL=(ALL:ALL) NOPASSWD:SETENV: ALL"))

  (keyboard-layout (keyboard-layout "us"))

  (packages
    (append
     (map specification->package
          '("nss-certs" "openssh" "lvm2" "btrfs-progs" #;"e2fsprogs"
            "screen" "zsh" "rlwrap" #;"emacs"))
     %base-packages))

  (services
    (cons*
      #;(set-xorg-configuration
        (xorg-configuration
          #;(server-arguments '()) ;; disable the default '("-nolisten" "tcp") ;--- don't do it until we have a good firewall!
          (keyboard-layout keyboard-layout)
          (extra-config '()))) ;;TODO: set the device resolution
      (bluetooth-service #:auto-enable? #t)
      #;(service gpm-service-type)
      #;(service nix-service-type
        (nix-configuration
          (extra-config
           '("substituters = https://cache.nixos.org https://cache.nixos.org/ https://hydra.iohk.io https://iohk.cachix.org https://mukn.cachix.org\n"
             "trusted-substituters = https://cache.nixos.org https://cache.nixos.org/ https://hydra.iohk.io https://iohk.cachix.org https://mukn.cachix.org\n"
             "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo= hydra.goguen-ala-cardano.dev-mantis.iohkdev.io-1:wh2Nepc/RGAY2UMvY5ugsT8JOz84BKLIpFbn7beZ/mo= mukn.cachix.org-1:ujoZLZMpGNQMeZbLBxmOcO7aj+7E5XSnZxwFpuhhsqs=\n"))))
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
      #;(service cups-service-type
        (cups-configuration
          (web-interface? #t)
          (extensions
           (list brlaser cups-filters epson-inkjet-printer-escpr foomatic-filters
                 hplip-minimal splix)))) ;; gutenprint
      (modify-services %desktop-services
        (console-font-service-type _config =>
          (map (lambda (i)
                 (cons (format #f "tty~d" i)
		       (file-append font-terminus "/share/consolefonts/ter-v32i.psf.gz")))
               (iota 6 1)))
        (guix-service-type config =>
          (guix-configuration
            (inherit config)
            #;(substitute-urls (cons* "http://guix.drewc.ca:8080/" %default-substitute-urls))
            #;(authorized-keys (cons* (local-file "./druix-key.pub") %default-authorized-guix-keys))))
        (pulseaudio-service-type config =>
          (pulseaudio-configuration
           (inherit config)
           #;(script-file (local-file "/etc/guix/default.pa")) ;; ???
           )))))

  ;; Allow resolution of '.local' host names with mDNS.
  #;(name-service-switch %mdns-host-lookup-nss))