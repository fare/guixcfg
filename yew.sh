yew_hacks () {
  mount --bind /sys /guix/sys
  mount --bind /proc /guix/proc
  mount --bind /dev /guix/dev
  mount --bind /dev/pts /guix/dev/pts
  mount --bind /run /guix/run
  #mount -t tmpfs tmpfs /guix/tmp
  mount --bind /tmp /guix/tmp
  mount --bind /home /guix/home

  mount --bind /boot /guix/boot
  #mount /dev/nvme0n1p2 /guix/boot

  #mount --bind /guix/gnu /gnu
  #mount --bind /guix/var/guix /var/guix

  #guix-daemon --build-users-group=guixbuild --disable-chroot &

  mount -o remount,size=20G tmpsfs /tmp

  export HOME=/home/fare ZDOTDIR=/home/fare PSX="Guix " PATH=/home/fare/bin:/home/fare/bin/nix:/home/fare/etc/bin:/home/fare/.nix-profile/bin:/home/fare/.nix-profile/sbin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/run/current-system/sw/bin:/run/current-system/sw/sbin:/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/sw/sbin:/home/fare/.config/guix/current/bin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/usr/bin:/usr/sbin:/bin:/sbin

  chroot /guix /var/guix/profiles/system/profile/bin/zsh

  guix-daemon --build-users-group=guixbuild --disable-chroot &

  guix system reconfigure --load-path=/home/fare/src/fare/guixcfg/modules /home/fare/src/fare/guixcfg/mew.scm \
       /home/fare/src/fare/guixcfg/yew.scm &&
  cp /boot/grub/grub.cfg /boot/grub/grub.cfg.guix
  . ~/etc/zsh/cmd.o_guix
  fixboot
}
