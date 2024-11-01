mew_hacks () {
  for i in /dev/sda1 /mew ; do umount $i ; done
  vgchange -an mew
  cryptsetup luksClose mew.crypt

  cryptsetup luksOpen /dev/sda2 mew.crypt
  vgchange -ay

  mount /dev/mew/guix /mnt
  mount /dev/mew/nixos /mnt/nixos
  mount /dev/sda1 /mnt/boot

  mount /dev/mew/nixos /mnt
  mount /dev/mew/guix /mnt/guix
  mount /dev/sda1 /mnt/boot

  mount --bind /sys /mnt/sys
  mount --bind /proc /mnt/proc
  mount --bind /dev /mnt/dev
  mount --bind /run /mnt/run
  mount -t tmpfs tmpfs /mnt/tmp
  mount --bind /mnt/gnu /gnu
  mount --bind /mnt/var/guix /var/guix
  mount --bind /mnt/boot /boot
  guix-daemon --build-users-group=guixbuild &

  export HOME=/home/fare ZDOTDIR=/home/fare PSX="Mew " PATH=/home/fare/bin:/home/fare/bin/nix:/home/fare/etc/bin:/home/fare/.nix-profile/bin:/home/fare/.nix-profile/sbin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/run/current-system/sw/bin:/run/current-system/sw/sbin:/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/sw/sbin:/home/fare/.config/guix/current/bin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin

  chroot /mnt /var/guix/profiles/system/profile/bin/zsh
  guix system reconfigure --load-path=/home/fare/src/fare/guixcfg/modules:/home/fare/src/guix/guix-pinephonepro/src /home/fare/src/fare/guixcfg/mew.scm
  cp /boot/grub/grub.cfg /boot/grub/grub.cfg.guix

  namekill guix-daemon
  for i in /boot /mnt/boot /mnt/tmp /mnt/run/user/1000/gvfs /mnt/run/user/1000 /mnt/run/wrappers /mnt/run/keys /mnt/run /mnt/dev/mqueue /mnt/dev/hugepages /mnt/dev/shm /mnt/dev/pts /mnt/dev /mnt/proc /mnt/sys/fs/pstore /mnt/sys/kernel/config /mnt/sys/fs/fuse/connections /mnt/sys/kernel/debug /mnt/sys/fs/bpf /mnt/sys/firmware/efi/efivars /mnt/sys/fs/cgroup /mnt/sys/kernel/security /mnt/sys /gnu /guix/var/guix /mnt/nixos /mnt ; do umount $i ; done

}
