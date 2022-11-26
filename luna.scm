;; (non)guix configuration for Luna
;; # dmidecode -s system-version ==> ThinkPad X1 Extreme Gen 5
;; See https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Extreme_(Gen_5)
;; See https://github.com/dustinlyons/guix-config/blob/main/Workstation.org
;; TODO fix Yubikey issue on Chrome. At least, it now works on firefox.

(use-modules
  (gnu)
  (gnu system nss)
  (guix channels) (guix download) (guix inferior) (guix modules) (guix packages) (guix transformations)
  (nongnu packages fonts) (nongnu packages linux) (nongnu system linux-initrd)
  (nongnu packages nvidia) ;; NVIDIA -- all nvidia related lines are commented with this tag
  (srfi srfi-1))

(use-service-modules
  authentication cups dbus desktop dict nix security-token sound ssh xorg);; virtualization docker

(use-package-modules
  admin bootloaders certs cups fonts fontutils games ghostscript gnome linux lisp
  package-management screen shells ssh tex tls vpn wm xdisorg xorg)

(use-package-modules
  admin certs gnome linux vpn wm
  package-management ssh tls)

;; Inspired by https://github.com/nanjigen/literate-configurations/blob/main/guix-configurations.org
(define %u2f-udev-rule
  (file->udev-rule ;; Latest (so far) from https://github.com/Yubico/libfido2/blob/main/udev/70-u2f.rules
    "70-u2f.rules"
    (let ((version "7b7ce2bd5e7922f063c096ed12686fd64976c565"))
      (origin
       (method url-fetch)
       (uri (string-append "https://raw.githubusercontent.com/Yubico/libfido2/"
                           version "/udev/70-u2f.rules"))
       (sha256 (base32 "1009b1j6ns95lis2qmf3g3npc396wv9phx9fgwysbjq997c6m1vs"))))))

;; For NVIDIA support, see https://gitlab.com/nonguix/nonguix/-/issues/198
#;(define transform (options->transformation '((with-graft . "mesa=nvda")))) ;; NVIDIA

(define my-fonts
  (list font-terminus
        font-sun-misc font-sony-misc font-misc-misc font-adobe75dpi font-adobe100dpi
        font-google-noto font-google-roboto font-google-material-design-icons
        font-microsoft-web-core-fonts ;; font-bitstream-vera
        font-dejavu gs-fonts font-gnu-freefont ;; already there
        ;; font-alias font-awesome font-bitstream-vera font-gnu-freefont font-inconsolata font-mathjax
        ;; texlive-cm texlive-cm-super texlive-lm
        ))


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
          (inherit grub-efi-removable-bootloader)
          #;(installer #~(const #true)))) ;; "/dev/nvme0n1" "(hd0)"
      (targets '("/boot"))))

  (mapped-devices
    (list
      (mapped-device
        (source (uuid "9baf17ae-4031-44d6-a384-efd38895ee9d"))
        (target "lunacity.crypt")
        (type luks-device-mapping))
      (mapped-device
        (source "lunacity")
        (targets (list "lunacity-swap" "lunacity-root"))
        (type lvm-device-mapping))))

  (file-systems
    (append
     (let* ((root (file-system
                   (device "/dev/mapper/lunacity-root")
                   (mount-point "/")
                   (type "btrfs")
                   (flags '(lazy-time))
                   (options "compress=zstd")
                   (dependencies mapped-devices)))
            (boot (file-system
                   (device (uuid "CD34-D3C9" 'fat))
                   ;;(device "/dev/nvme0n1p1")
                   ;;(device "/dev/mmcblk0p1")
                   ;;(device "/dev/sda1")
                   (mount-point "/boot")
                   (flags '(lazy-time))
                   (type "vfat"))))
       (cons* root boot %base-file-systems))))

  (swap-devices
   (list
    (swap-space
     (target "/dev/lunacity/swap")
     (discard? #t)
     (dependencies mapped-devices))))

  (kernel linux)
  (kernel-arguments
    (cons*
      "ibt=off" ;; Video related says the ArchLinux page
      #;"modprobe.blacklist=nouveau" ;; NVIDIA
      "zswap.enabled=1" "zswap.compressor=zstd" ;; for btrfs
      "zswap.max_pool_percent=50" "zswap.zpool=z3fold"
      %default-kernel-arguments))
  #;(kernel-loadable-modules (list nvidia-driver)) ;; NVIDIA
  (initrd-modules
    (cons*
      "zstd" "z3fold"
      "video" "i915"
      ;;"snd-pcm-oss" "snd-mixer-oss" ;; somehow don't get autoloaded but mplayer wants it by default
      %base-initrd-modules))

  (initrd microcode-initrd)
  (firmware (cons* linux-firmware iwlwifi-firmware #;broadcom-bt-firmware sof-firmware
                   %base-firmware))

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

  (issue "Welcome to Luna City, birthplace of Adam Selene.\n")

  (packages
    (append
     (map specification->package
          '(#;SURVIVE "emacs" "git" "rlwrap" "screen" "zsh"
            #;STORAGE "btrfs-progs" "cryptsetup" "e2fsprogs" "lvm2"
            #;HARDWARE "bluez" "bluez-alsa" "cups" "inxi" ;; "light" "brightnessctl"
            #;SOUND "alsa-utils" "audacity" "aumix" "pamixer" "pavucontrol" "pulseaudio" ;;"pulsemixer" "volctl"
            #;SYSTEM "lsof"
            #;BUILD "gcc-toolchain" "linux-libre-headers" "make" "racket" "sbcl"
            #;NETUTILS "iftop" "mtr" "nss-certs" "openssh" "rsync" "sshfs" "oath-toolkit"
            #;NETAPPS "curl" "hexchat" "wget"
            #;BROWSE "emacs-edit-server" "firefox" "ublock-origin-chromium"
                     "ungoogled-chromium" "w3m" "icecat" ;; "lynx"
            #;COMMS "hexchat" "signal-desktop" #;"telegram-cli" "telegram-desktop"
            #;FILES "findutils" "tar" "unzip" "zip"
            ;; TODO: add to nonguix fortune-mod and other related packages that were removed from guix for offending the politically correct humorlessness of some maintainers? https://debbugs.gnu.org/cgi/bugreport.cgi?bug=54691 guix commits: f592decd4d823a973600d4cdd9f3f7d3ea610429 5e174805742b2bec9f5a06c9dd208c60b9af5c14 6b6b947b6133c40f86800dc0d36a59e16ac169fc
            #;TEXTDATA "dico" "daikichi" "fortunes-jkirchartz" "units"
            #;TEXTUTILS "diffutils" "gawk" "sed" "m4" "perl" "patch" "recode" "wdiff"
            #;VIDEO "mplayer" "vlc"
            #;GRAPHICS "imagemagick" "feh" "gimp" "inkscape" "qiv" ;; fbida
            #;MARKUP "markdown" "python-docutils" "texlive" ;; "guile-commonmark"
            #;DOCUMENTS "evince" "libreoffice" "xournal"
            #;FONT-UTILS "fontconfig" "gnome-font-viewer" "xfontsel" "xlsfonts" ;; "fontmanager"
            #;XUTILS "xdpyinfo" "xmodmap" "xrandr" "xrdb" "xset" "xsetroot" "xwininfo"
            #;XPROGS "synergy" "stumpwm" "terminator" "xterm" "xscreensaver")) ;; "ratpoison"
     my-fonts
     %base-packages))

  (services
    (cons*
      (set-xorg-configuration
        (xorg-configuration
          (server-arguments '("-dpi" "189")) ;; Mimic what nixos does witht the DPI setting?
          #;(server-arguments '()) ;; disable the default '("-nolisten" "tcp") ;--- don't do it until we have a good firewall!
          (keyboard-layout keyboard-layout)
          (extra-config '())
          (fonts (append my-fonts %default-xorg-fonts))
          #;(server (transform xorg-server)) ;; NVIDIA
          #;(modules (cons* nvidia-driver %default-xorg-modules)) ;; NVIDIA
          #;(drivers '("nvidia")))) ;; NVIDIA
      ;;#;(service kernel-module-loader-service-type '("nvidia_uvm")) ;; NVIDIA
      #;(simple-service 'custom-udev-rules udev-service-type (list nvidia-driver)) ;; NVIDIA
      (screen-locker-service xlockmore "xlock") ;; Use xscreensaver instead?
      (bluetooth-service #:auto-enable? #t)
      (service gpm-service-type)
      #;(service nix-service-type
        (nix-configuration
          (extra-config
           '("substituters = https://cache.nixos.org https://cache.nixos.org/ https://hydra.iohk.io https://iohk.cachix.org https://mukn.cachix.org\n"
             "trusted-substituters = https://cache.nixos.org https://cache.nixos.org/ https://hydra.iohk.io https://iohk.cachix.org https://mukn.cachix.org\n"
      "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo= hydra.goguen-ala-cardano.dev-mantis.iohkdev.io-1:wh2Nepc/RGAY2UMvY5ugsT8JOz84BKLIpFbn7beZ/mo= mukn.cachix.org-1:ujoZLZMpGNQMeZbLBxmOcO7aj+7E5XSnZxwFpuhhsqs=\n"))))
      (dicod-service #:config
       (dicod-configuration
        (databases (list ;; TODO: package and add other databases?
                    %dicod-database:gcide))))
      (service openssh-service-type
        (openssh-configuration
          (openssh openssh)
          (x11-forwarding? #t)
          (password-authentication? #false)
          (authorized-keys
            `(("fare" ,(local-file "/home/fare/.ssh/id_rsa.pub"))
              ("root" ,(local-file "/home/fare/.ssh/id_rsa.pub"))))))
      #;(service fprintd-service-type)
      (service pcscd-service-type)
      (pam-limits-service
        (list
          (pam-limits-entry "@audio" 'both 'rtprio 99)
          (pam-limits-entry "@audio" 'both 'memlock 'unlimited)))
      #;(service libvirt-service-type (libvirt-configuration (unix-sock-group "libvirt") (tls-port "16555")))
      #;(service virtlog-service-type (virtlog-configuration (max-clients 1000)))
      #;(service singularity-service-type)
      #;(service docker-service-type)
      (service cups-service-type
        (cups-configuration
          (web-interface? #t)
          (extensions
           (list brlaser cups-filters foomatic-filters)))) ;; epson-inkjet-printer-escpr hplip-minimal splix gutenprint
      (modify-services %desktop-services
        (console-font-service-type _config =>
          (map (lambda (i)
                 (cons (format #f "tty~d" i)
                       (file-append font-terminus "/share/consolefonts/ter-v32i.psf.gz")))
               (iota 6 1)))
        (udev-service-type config =>
                           (udev-configuration (inherit config)
                                               (rules (cons %u2f-udev-rule
                                                            (udev-configuration-rules config)))))
        (guix-service-type config =>
          (guix-configuration
            (inherit config)
            (substitute-urls (cons* ;;"http://guix.drewc.ca:8080/"
                                    "https://substitutes.nonguix.org"
                                    "https://bordeaux.guix.gnu.org"
                                    %default-substitute-urls))
            (authorized-keys (cons* (local-file "./nonguix-key.pub")
                                    (local-file "./bordeaux-key.pub")
                                    %default-authorized-guix-keys))))
        (pulseaudio-service-type config =>
          (pulseaudio-configuration
            (inherit config)
            #;(script-file (local-file "/etc/guix/default.pa")) ;; ???
            )))))

  ;; Allow resolution of '.local' host names with mDNS.
  #;(name-service-switch %mdns-host-lookup-nss))
