: 'Initialize the metasystem with the following:

mount /dev/mmcblk1p1 /mnt
. /mnt/ia.sh
ini

'

disk=mmcblk1
host=deepness
bootpart=${disk}p1
cryptpart=${disk}p2

### Code below

ini () {
 (set -x
  umount /mnt
  cryptsetup luksOpen /dev/${cryptpart} ${host}.crypt
  vgchange -ay
  swapon /dev/mapper/${host}-swap
  ####vvv
  mount /dev/${host}/pinephone /mnt
  mkdir -p /mnt/data
  mount /dev/${host}/data /mnt/data
  #mount /dev/${bootpart} /mnt/boot
  mount --rbind /boot /mnt/boot
  ####^^^
  mkdir -p /mnt/sys /mnt/proc /mnt/dev /mnt/run /mnt/tmp /mnt/gnu /mnt/var/guix /mnt/gnu/store /mnt/root
  mount --rbind /sys /mnt/sys
  mount --rbind /sys /mnt/sys
  mount --rbind /proc /mnt/proc
  mount --rbind /dev /mnt/dev
  mount --rbind /run /mnt/run
  #mount --rbind /tmp /mnt/tmp
  mount -t tmpfs tmpfs /mnt/tmp
  mount --bind /mnt/gnu /gnu
  ln -s /mnt/var/guix /var/
  mount --bind /mnt/root /root

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

ip () {
  apt update ; apt install -y emacs screen less zsh btrfs-progs
}

im () {
  HOME=/root
  PATH=/run/setuid-programs:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/bin:/sbin
  chroot /mnt "$@"
}

f () {
  . /mnt/boot/ia.sh
}

re () {
  im guix system reconfigure /boot/${host}.scm
}

fix () {
  a=( $(grep /gnu/store /mnt/boot/grub/grub.cfg | grep -v '^#' | sed 's,^\(.*\)\?/gnu/store/\([^ ;]\+\).*$,\2,' | sort -u) )
  mkdir -p /mnt/boot/gnu/store
  ( cd /mnt/gnu/store && rsync -cLRrv --delete $a /mnt/boot/gnu/store/ )
  cp /mnt/boot/grub/grub.cfg /mnt/boot/grub/grub.cfg.bak
  sed 's,^cryptomount,#cryptomount,' < /mnt/boot/grub/grub.cfg.bak > /mnt/boot/grub/grub.cfg
}
