: 'Initialize the metasystem with the following:

mount /dev/nvme0n1p1 /mnt
. /mnt/foo
ini

'


### Code below

ini () {
 (set -x
  umount /mnt
  cryptsetup luksOpen /dev/nvme0n1p2 luna.crypt
  vgchange -ay
  swapon /dev/mapper/luna-swap
  mount /dev/mapper/luna-root /mnt
  mount /dev/nvme0n1p1 /mnt/boot
  mount --rbind /sys /mnt/sys
  mount --rbind /sys /mnt/sys
  mount --rbind /proc /mnt/proc
  mount --rbind /dev /mnt/dev
  mount --rbind /run /mnt/run
  #mount --rbind /tmp /mnt/tmp
  mount -t tmpfs tmpfs /mnt/tmp
  mkdir -p /gnu
  mount --bind /mnt/gnu /gnu
  #mkdir -p /mnt/var/guix
  ln -s /mnt/var/guix /var/

  cp /etc/ssh/*key* /etc/ssh/
  service ssh start

  groupadd --system guixbuild
  for i in $(seq -w 1 10); do
    useradd -g guixbuild -G guixbuild \
            -d /var/empty -s "$(which nologin)" \
            -c "Guix build user $i" --system \
            "guixbuilder${i}";
  done
  im guix-daemon --build-users-group=guixbuild &
  )
}

ie () {
  apt update ; apt install -y emacs screen less zsh
}

im () {
  HOME=/root
  PATH=/run/setuid-programs:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/bin:/sbin
  chroot /mnt "$@"
}

f () {
  . /mnt/boot/foo
}

re () {
  im guix system reconfigure /boot/luna.scm
}

fix () {
  a=( $(grep /gnu/store /mnt/boot/grub/grub.cfg | grep -v '^#' | sed 's,^\(.*\)\?/gnu/store/\([^ ;]\+\).*$,\2,' | sort -u) )
  mkdir -p /mnt/boot/gnu/store
  ( cd /mnt/gnu/store && rsync -cLRrv --delete $a /mnt/boot/gnu/store/ )
  cp /mnt/boot/grub/grub.cfg /mnt/boot/grub/grub.cfg.bak
  sed 's,^cryptomount,#cryptomount,' < /mnt/boot/grub/grub.cfg.bak > /mnt/boot/grub/grub.cfg
}
