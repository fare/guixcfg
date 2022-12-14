;; (non)guix configuration for Luna, a PINE64 PinePhone Pro

;; Built at this commit: guix pull --commit=eb5e650


;; References
;;
;; PinePhone in general:
;; For tow-boot, see https://wiki.mobian-project.org/doku.php?id=install-linux
;; https://wiki.pine64.org/wiki/PinePhone_Pro_Software_Releases#Mobian
;;
;; Guix & Nonguix in general and for the PinePhone:
;; https://guix.gnu.org/manual/en/guix.html
;; https://wiki.systemcrafters.cc/guix/nonguix-installation-guide
;; https://github.com/Schroedinger50PCT/guix-pinephone/blob/main/pinephone_config.scm
;;
;; Keyboard issue:
;; https://codeberg.org/HazardChem/PinePhone_Keyboard/src/branch/main/xkb
;; https://codeberg.org/HazardChem/PinePhone_Keyboard/src/branch/main/tty
;; http://blog.azundris.com/archives/193-X-treme-pain-XKB-vs-XModMap.html
;; https://wiki.archlinux.org/title/X_keyboard_extension

(define-module (deepness))

(use-modules
  (gnu) (gnu bootloader u-boot) (gnu system nss)
  (guix channels) (guix inferior) (guix modules)
  ;;(nongnu packages fonts) ;; (nongnu packages linux) (nongnu system linux-initrd)
  (srfi srfi-1))

(use-service-modules
  authentication dbus desktop dict nix security-token sound ssh xorg);; virtualization docker

(use-package-modules
  admin bootloaders certs cups fonts fontutils games ghostscript gnome linux lisp
  package-management screen shells ssh tex tls vpn wm xorg)

(define my-fonts
  (list font-terminus
        font-sun-misc font-sony-misc font-misc-misc font-adobe75dpi font-adobe100dpi
        font-google-noto font-google-roboto font-google-material-design-icons
        ;;font-microsoft-web-core-fonts ;; font-bitstream-vera
        font-dejavu gs-fonts font-gnu-freefont ;; already there
        ;; font-alias font-awesome font-bitstream-vera font-gnu-freefont font-inconsolata font-mathjax
        ;; texlive-cm texlive-cm-super texlive-lm
        ))

(operating-system
  (host-name "deepness")
  (timezone "America/New_York")
  (locale "en_US.UTF-8")

  ;; BEWARE: Guix does not support a separate /boot partition yet http://issues.guix.gnu.org/48172
  ;;; (bootloader (bootloader-configuration (bootloader grub-bootloader) (target "/dev/nvme0n1")))
  ;; So instead, we'll generate a grub configuration and we'll integrate it into the grub from NixOS
  ;; with the guix-boot.ss script (written in Gerbil Scheme).
  ;; From http://guix.gnu.org/en/cookbook/en/html_node/Running-Guix-on-a-Linode-Server.html --
  ;; This goofy code will generate the grub.cfg without installing the grub bootloader on disk.
  (bootloader (bootloader-configuration
                (bootloader u-boot-pine64-lts-bootloader)
                (targets '("/dev/mmcblk2"))))

  (mapped-devices
    (list
      (mapped-device
        (source (uuid "e984d34b-f23f-4515-8f5f-aa8cd67fd11b"))
        (target "deepness.crypt")
        (type luks-device-mapping))
      (mapped-device
        (source "deepness")
        (targets (list "deepness-swap" "deepness-root"))
        (type lvm-device-mapping))))

  (file-systems
    (append
     (let* ((root (file-system
                   (device "/dev/mapper/deepness-pinephone")
                   (mount-point "/")
                   (type "brtfs")
                   (flags '(lazy-time))
                   (dependencies mapped-devices)))
            (data (file-system
                   (device "/dev/mapper/deepness-data")
                   (mount-point "/data")
                   (type "brtfs")
                   (flags '(lazy-time))
                   (options "compress=zstd")
                   (dependencies mapped-devices)))
            (boot (file-system
                   ;;(uuid "FBD5-92B7")
                   (device "/dev/mmcblk1p1")
                   (mount-point "/boot")
                   (flags '(lazy-time))
                   (type "vfat"))))
       (cons* root boot %base-file-systems))))

  (swap-devices
   (list
    (swap-space
     (target "/dev/deepness/swap")
     (discard? #t)
     (dependencies mapped-devices))))

  (kernel linux-libre-arm64-generic)
  (kernel-arguments
   '("iommu=soft"
     "nvme_core.default_ps_max_latency_us=0" ;; needed to fix broken i660p m2 nvme disk on PinePhone
     "zswap.enabled=1" "zswap.compressor=zstd"
     "zswap.max_pool_percent=50" "zswap.zpool=z3fold"))
  (initrd-modules
    (cons*
      "zstd" "z3fold"
      ;;"snd-pcm-oss" "snd-mixer-oss" ;; somehow don't get autoloaded but mplayer wants it by default
      %base-initrd-modules))

  ;;(initrd microcode-initrd)
  (firmware
    (cons* #;linux-firmware #;ath9k-htc-firmware %base-firmware))

  (users
   (append
    (list
     (user-account
      (name "fare")
      (comment "Francois-Rene Rideau")
      (group "users")
      (shell (file-append zsh "/bin/zsh"))
      ;; Adding the account to the "wheel" group makes it a sudoer.
      (supplementary-groups '("wheel" "audio" "video"))
      (home-directory "/home/fare")))
    %base-user-accounts))

  (sudoers-file (plain-file "sudoers"
                            "root ALL=(ALL:ALL) SETENV: ALL
%wheel ALL=(ALL:ALL) NOPASSWD:SETENV: ALL"))

  (keyboard-layout (keyboard-layout "us"))

  (issue "Welcome to my Deepness in the Sky, Qeng Ho starship.\n")

  (packages
    (append
     (map specification->package
          '(#;SURVIVE #;"emacs" "git" "rlwrap" "screen" "zsh"
            #;STORAGE "btrfs-progs" "cryptsetup" "e2fsprogs" "lvm2"
            #;SYSTEM "lsof" ;;"fbterm"
            #;NETUTILS "iftop" "mtr" "nss-certs" "openssh" "rsync" "sshfs"))
     #|
            #;HARDWARE "bluez" "bluez-alsa" "cups" "inxi" ;; "light" "brightnessctl"
            #;SOUND "alsa-utils" "audacity" "aumix" "pamixer" "pavucontrol" "pulseaudio" ;;"pulsemixer" "volctl"
            #;NETAPPS "curl" "hexchat" "wget"
            #;BROWSE ;; "emacs-edit-server" "firefox" "ublock-origin-chromium" "ungoogled-chromium"
                     "icecat" "w3m"
            ;;#;COMMS "hexchat" "signal-desktop" #;"telegram-cli" "telegram-desktop"
            #;FILES "findutils" "tar" "unzip" "zip"
            ;; TODO: add to nonguix fortune-mod and other related packages that were removed from guix for offending the politically correct humorlessness of some maintainers? https://debbugs.gnu.org/cgi/bugreport.cgi?bug=54691 guix commits: f592decd4d823a973600d4cdd9f3f7d3ea610429 5e174805742b2bec9f5a06c9dd208c60b9af5c14 6b6b947b6133c40f86800dc0d36a59e16ac169fc
            #;TEXTDATA "dico" "daikichi" "fortunes-jkirchartz"
            #;TEXTUTILS "diffutils" "gawk" "sed" "m4" "perl" "patch" "recode" "wdiff"
            #;LANGUAGES ;; "make" "racket" "sbcl"
            #;VIDEO "vlc" ;; "mplayer"
            #;GRAPHICS "imagemagick" "feh" ;; "fbida" "gimp" "inkscape" "qiv"
            #;MARKUP "markdown" "python-docutils" ;; "texlive" ;; "guile-commonmark"
            #;DOCUMENTS "evince" ;; "libreoffice" "xournal"
            #;FONT-UTILS "xfontsel" "xlsfonts" ;; "gnome-font-viewer" "fontconfig" "fontmanager"
            #;XUTILS "xdpyinfo" "xmodmap" "xrandr" "xrdb" "xset" "xsetroot" "xwininfo"
            #;XPROGS "synergy" "stumpwm" "terminator" "xterm" "xscreensaver" ;; "ratpoison"
     |#
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
      #;(dicod-service #:config
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
      #;(service pcscd-service-type)
      #;(pam-limits-service
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
      (modify-services %base-services ;; %desktop-services
        (delete gdm-service-type) (delete gdm-file-system-service)
        (console-font-service-type _config =>
          (map (lambda (i)
                 (cons (format #f "tty~d" i)
                       (file-append font-terminus "/share/consolefonts/ter-v24i.psf.gz")))
               (iota 6 1)))
        (guix-service-type config =>
          (guix-configuration
            (inherit config)
            (substitute-urls (cons*
                              ;;"http://guix.drewc.ca:8080/"
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
