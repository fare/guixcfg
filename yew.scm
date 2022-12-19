
(define-module (yew))

(use-modules
  (common) (gnu system file-systems))

(my-pc "yew"
  #:crypted-part-uuid "6761c21c-1188-4955-9109-3efb088efc05"
  #:crypted-lvms '("swap" "nixos" "home" "guix")
  ;;#:boot-target "/boot/guix"
  #:file-systems
  (lambda (mapped-devices)
    (define nixos
      (file-system
       ;;(device "/dev/yew/nixos")
       (device (uuid "ab3d691b-227a-4a05-a084-6928abbf0959"))
       (mount-point "/nixos")
       (type "ext4")
       (flags '(lazy-time))
       (dependencies mapped-devices)))
    (list (file-system
           ;;(device "/dev/mapper/yew-guix")
           (device (uuid "43f7ca3e-c107-4f15-9756-5d3cbacad0a0"))
           (mount-point "/")
           (type "btrfs")
           (flags '(lazy-time))
           (options "compress=zstd")
           (dependencies mapped-devices))
          (file-system
           ;;(device "/dev/yew/swap")
           (device (uuid "1a3915f9-c00c-4e62-ab7d-d6d7a2641e4d"))
           (mount-point "swap")
           (type "swap")
           (dependencies mapped-devices))
          (file-system
           ;;(device "/dev/yew/home")
           (device (uuid "a3602532-3527-4afc-9b40-5d01c58b5aa8"))
           (mount-point "/home")
           (type "ext4")
           (flags '(lazy-time))
           (dependencies mapped-devices))
          nixos
          (file-system
           ;;(uuid "C1D9-0574")
           (device "/dev/nvme0n1p1")
           (mount-point "/nixos/boot")
           (flags '(lazy-time))
           (type "vfat"))
          (file-system ;; see https://issues.guix.gnu.org/issue/35472
           (device "/nixos/nix")
           (mount-point "/nix")
           (type "none")
           (flags '(bind-mount lazy-time))
           (dependencies (list nixos)))))
  #:kernel-arguments
  '("quiet"
    "zswap.enabled=1" "zswap.compressor=zstd"
    "zswap.max_pool_percent=50" "zswap.zpool=z3fold")
  #:initrd-modules
  '("zstd" "z3fold"
    "video" "i915"
    "snd-pcm-oss" "snd-mixer-oss") ;; somehow don't get autoloaded but mplayer wants it by default
  #:issue "Welcome to Yew, the City of Justice.\n"
  #:dpi 189)
