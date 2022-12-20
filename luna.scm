;; (non)guix configuration for Luna
;; # dmidecode -s system-version ==> ThinkPad X1 Yoga Gen 7
;; See https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Yoga_(Gen_7)
;; See https://github.com/dustinlyons/guix-config/blob/main/Workstation.org

(define-module (luna))

(my-pc "luna"
  #:crypted-part-uuid "914ced29-213f-46ce-a573-98090a2d4768"
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
      (device (uuid "7007-58F2" 'fat))
      (mount-point "/boot")
      (flags '(lazy-time))
      (type "vfat"))))
  #:kernel-arguments
  '("ibt=off") ;; Video related says the ArchLinux page
  #:initrd-modules '("video" "i915")
  #:issue "Welcome to Luna City, home of Adam Selene.\n"
  #:dpi 323)
