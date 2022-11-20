#!/usr/bin/env gxi

;; In my ~/.zshenv, I added:
;;   GUIX_PROFILE="/root/.config/guix/current" ; \
;;   [ -d ${GUIX_PROFILE}/bin ] 2> /dev/null && add_path ${GUIX_PROFILE}/bin
;; And to install guix from NixOS, first I make sure the daemon is run with:
;;   guix-daemon --build-users-group=guixbuild &
;; And then I use:
;;   guix system init guix-config.scm /guix && /root/guix-boot.ss && sync
;; I want to be able to test it like that:
;;   qemu-kvm -m 2G -drive file=/dev/nvme0n1,if=virtio,readonly=on
;; But somehow the guix kernel tries to load the kvm module, fails, and stops with an error

(import
  :std/misc/list :std/misc/ports :std/misc/process :std/misc/string
  :std/pregexp :std/srfi/1 :std/srfi/13 :std/sugar)

;; From clan/base
(def rcompose
  (case-lambda
    (() values)
    ((f) f)
    ((f1 f2) (lambda args (call-with-values (lambda () (apply f1 args)) f2)))
    ((f1 f2 f3 . fs) (rcompose f1 (apply rcompose f2 f3 fs)))))
(def !> ;; see x |> f in ML
  (case-lambda
    ((x) x)
    ((x f) (f x))
    ((x f1 f2 . fs) ((apply rcompose f1 f2 fs) x))))

;; From clan/path
(def (path-simplify path keep..?: (keep..? #f))
  (def l (string-split path #\/))
  (def abs? (and (pair? l) (equal? (car l) "")))
  (set! l (remove (cut member <> '("" ".")) l))
  (unless keep..?
    (let loop ((head (reverse l)) (tail '()))
      (cond
       ((and (pair? head) (pair? tail) (equal? (car tail) "..") (not (equal? (car head) "..")))
        (loop (cdr head) (cdr tail)))
       ((pair? head)
        (loop (cdr head) (cons (car head) tail)))
       (else (set! l tail))))
    (when abs?
      (while (and (pair? l) (equal? (car l) ".."))
        (set! l (cdr l)))))
  (if (null? l)
    (if abs? "/" "") ;; "" is the standard "here" path, though we could have picked ".".
    (begin
      (when abs?
        (set! l (cons "" l)))
      (string-join l "/"))))
(def (path-maybe-normalize path)
  (with-catch (lambda (_) (path-simplify path)) (cut path-normalize path)))
(def (path-parent path)
  (path-maybe-normalize (path-expand ".." path)))


(def (get-mounts)
  (map (cut string-split <> #\space) (read-file-lines "/proc/mounts")))

;; 1. resolve, then go up until a mount point is found?
;; 2. call df and see what it uses
(def (find-exact-mount x)
  (find (lambda (l) (equal? (path-normalize (second l)) (path-normalize x))) (get-mounts)))

(def (readlink path) ;; TODO: use the FFI instead!
  (string-trim-eol (run-process ["readlink" path])))

(def (partition-id device)
  (def ddbu "/dev/disk/by-uuid/")
  (def dev (string-trim-prefix "/dev/" device))
  (assert! (not (equal? dev device)))
  (def uuids (directory-files ddbu))
  (def (dev-id? u)
    (equal? dev (string-trim-prefix "../../" (readlink (string-append ddbu u)))))
  (find dev-id? uuids))

(def boot-mount (find-exact-mount "/nixos/boot"))

(def boot-uuid (partition-id (first boot-mount)))

(def guix-grub-cfg (read-file-lines "/guix/boot/grub/grub.cfg"))

(def dirs '())

(def (process-menu-line line)
  (cond
   ((pregexp-match "^  search --fs-uuid --set .*$" line)
    (string-append "  search --fs-uuid --set " boot-uuid))
   ((pregexp-match "^  linux ([^ ]+) .*$" line) =>
    (match <> ([_ bzImage] (push! (path-parent bzImage) dirs) line)))
   ((pregexp-match "^  initrd ([^ ]+)$" line) =>
    (match <> ([_ initrd] (push! (path-parent initrd) dirs) line)))
   (else line)))

(def menu-entry
  [(!> guix-grub-cfg
       (cut drop-while (lambda (x) (not (string-prefix? "menuentry " x))) <>)
       cdr
       (cut take-until (cut equal? "}" <>) <>)
       (cut map process-menu-line <>))...])

(def (in-mnt x) (string-append "/guix" x))

(run-process/batch ["rsync" "-a" "--delete" (map in-mnt dirs)...  "/nixos/boot/gnu/store/"])

(def obsolete-gnu-store-dirs
  (letrec ((up-to-date-dirs (map (cut string-trim-prefix "/gnu/store/" <>) dirs))
           (up-to-date? (lambda (dir) (member dir up-to-date-dirs))))
    (!> (directory-files "/nixos/boot/gnu/store/")
        (cut remove up-to-date? <>))))

(run-process/batch ["rm" "-rf" (map (lambda (x) (string-append "/nixos/boot/gnu/store/" x))
                                    obsolete-gnu-store-dirs) ...])

;; Create the menu entry file
(write-file-lines "/nixos/boot/grub/grub.cfg.guix" menu-entry)
