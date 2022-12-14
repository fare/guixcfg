;; (non)guix configuration for Luna
;; # dmidecode -s system-version ==> ThinkPad X1 Extreme Gen 5
;; See https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Extreme_(Gen_5)
;; See https://github.com/dustinlyons/guix-config/blob/main/Workstation.org
;; TODO fix Yubikey issue on Chrome. At least, it now works on firefox.

(define-module (luna))

(my-pc "luna"
  #:crypted-part-uuid "9baf17ae-4031-44d6-a384-efd38895ee9d"
  #:crypted-lvms '("swap" "root")
  #:file-systems
  (lambda (mapped-devices)
    (list
     (file-system
      (device "/dev/luna/root")
      (mount-point "/")
      (type "ext4")
      (flags '(lazy-time))
      (dependencies mapped-devices))
     (file-system
      (device (uuid "CD34-D3C9" 'fat))
      (mount-point "/boot")
      (flags '(lazy-time))
      (type "vfat"))))
  #:kernel-arguments
  '("ibt=off") ;; Video related says the ArchLinux page
  #:initrd-modules '("video" "i915")
  #:issue "Welcome to Luna City, home of Adam Selene.\n"
  #:dpi 189)
