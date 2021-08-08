;; Jackhill: https://paste.debian.net/1206838/

(use-modules (gnu) (gnu system nss)
	     (guix modules)
	     (nongnu packages linux)
	     (nongnu system linux-initrd)
             )
(use-service-modules desktop networking ssh xorg)
(use-package-modules admin certs gnome linux vpn wm
		     package-management
		     ssh
		     tls)

(operating-system
 (host-name "yew")
 (timezone "America/New_York")
 (locale "en_US.UTF-8")

 ;; BEWARE: Guix does not support a separate /boot partition yet http://issues.guix.gnu.org/48172
 ;;; (bootloader (bootloader-configuration (bootloader grub-bootloader) (target "/dev/nvme0n1")))
 ;; So instead, we'll generate a grub configuration and we'll integrate it manually
 ;; into the grub from NixOS.
 ;; From http://guix.gnu.org/en/cookbook/en/html_node/Running-Guix-on-a-Linode-Server.html --
 ;; This goofy code will generate the grub.cfg without installing the grub bootloader on disk.
 (bootloader (bootloader-configuration
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
  (cons*
   (file-system
    ;;(uuid "C1D9-0574")
    (device "/dev/nvme0n1p1")
    (mount-point "/boot")
    (type "vfat"))
   (file-system
    ;;(device "/dev/mapper/yew-guix")
    (device (uuid "43f7ca3e-c107-4f15-9756-5d3cbacad0a0"))
    (mount-point "/")
    (type "btrfs")
    #;(flags '(no-atime))
    (options "compress=zstd")
    (dependencies mapped-devices))
   (file-system
    ;;(device "/dev/yew/home")
    (device (uuid "a3602532-3527-4afc-9b40-5d01c58b5aa8"))
    (mount-point "/home")
    (type "ext4")
    (dependencies mapped-devices))
   (file-system
    ;;(device "/dev/yew/nixos")
    (device (uuid "ab3d691b-227a-4a05-a084-6928abbf0959"))
    (mount-point "/nixos")
    (type "ext4")
    (dependencies mapped-devices))
   %base-file-systems))

 (swap-devices (list (uuid "1a3915f9-c00c-4e62-ab7d-d6d7a2641e4d"))) ;; "/dev/yew/swap"

 ;;(kernel linux)
 (kernel-arguments '("quite"
		     "zswap.enabled=1" "zswap.compressor=zstd"
		     "zswap.max_pool_percent=50" "zswap.zpool=z3fold"))
 (initrd-modules
  (cons* "virtio_scsi"    ; Needed to find the disk
         "zstd" "z3fold"
         #;"ehci_hcd" "ahci" #;"usb_storage" "usbhid"
         #;"ext4" #;"vfat" "ccm" #;"ctr"
         "video" "i915"
         ;; "kvm-intel" "kvm-amd"
         "virtio"
         #;"tun"
         "coretemp"
         "psmouse"
         "fuse"
         #;"dm_crypt" #;"aes_generic" "cryptd" #;"sha256_generic"
         #;"cbc" "xts"
         #;"dm_mod" "arc4" #;"ecb" #;"sd_mod" #;"snd_hda_intel"
         #;"uhci_hcd"
         "r8169"
         #;"mmc_core" "mmc_block" "sdhci" "sdhci_pci"
         #;"nvme" "rtsx_pci_sdmmc"
	 %base-initrd-modules))

 (initrd microcode-initrd)
 (firmware (append (list linux-firmware iwlwifi-firmware broadcom-bt-firmware)
		   %base-firmware))

 (users (cons (user-account
	       (name "fare")
	       (group "users")
	       ;; Adding the account to the "wheel" group
	       ;; makes it a sudoer.
	       (supplementary-groups '("wheel" "audio" "video")) ; in NixOS, I also have: "fare" "root" "networkmanager" "kvm" "adbusers" "plugdev" "ftp" ;; jackhill also uses "netdev" "dialout"
	       (home-directory "/home/fare"))
	      %base-user-accounts))

 (packages (cons* nss-certs            ;for HTTPS access
		  openssh
		  lvm2
		  ;;btrfs-progs
		  wireguard-tools
		  sway
                  gvfs ;; for user mounts
		  %base-packages))

 (services (cons*
            (service xfce-desktop-service-type)
            #;(service xfce-desktop-service-type)
	    (service dhcp-client-service-type)
	    (service openssh-service-type
		     (openssh-configuration
		      (openssh openssh)
		      (password-authentication? #false)
		      (authorized-keys
		       `(("fare" ,(local-file "/home/fare/.ssh/id_rsa.pub"))
			 ("root" ,(local-file "/home/fare/.ssh/id_rsa.pub"))))))
	    %base-services))

 ;; Allow resolution of '.local' host names with mDNS.
 (name-service-switch %mdns-host-lookup-nss))
