;; # dmidecode -s system-version ==> ThinkPad X1 Yoga 2nd
;; Backup installation of Yew on a SD Card
;; guix pull --commit=989a3916dc8967bcb7275f10452f89bc6c3389cc # Pin to version 1.4.0

(define-module (mew))

(use-modules
  (common) (gnu system file-systems))

(my-pc "mew"
  #:crypted-part-uuid "9baf17ae-4031-44d6-a384-efd38895ee9d"
  #:crypted-lvms '("swap" "nixos" "guix")
  #:file-systems
  (lambda (mapped-devices)
    (list
     (file-system
      (device "/dev/mew/guix")
      (mount-point "/")
      (type "ext4")
      (flags '(lazy-time))
      (dependencies mapped-devices))
     (file-system
      (device "/dev/mew/nixos")
      (mount-point "/nixos")
      (type "ext4")
      (flags '(lazy-time))
      (dependencies mapped-devices))
     (file-system
      (device (uuid "CD34-D3C9" 'fat))
      (mount-point "/boot")
      (flags '(lazy-time))
      (type "vfat"))))
  #:initrd-modules '("video" "i915")
  #:issue "Welcome to Mew, mobile edition of Yew, the City of Justice.\n"
  #:dpi 189)
