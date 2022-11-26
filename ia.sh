: 'Initialize the metasystem with the following:

mount /dev/mmcblk1p1 /mnt
. /mnt/ia.sh
ini

'

disk=sda
host=lunacity
part=${disk}
#part=${disk}p
bootpart=${part}1
cryptpart=${part}2

### Code below

ini () {
 (set -x
  umount /mnt
  cryptsetup luksOpen /dev/${cryptpart} ${host}.crypt
  vgchange -ay
  swapon /dev/mapper/${host}-swap
  ####vvv
  mount /dev/${host}/root /mnt
  mount /dev/${bootpart} /mnt/boot
  ###
  #mount /dev/${host}/pinephone /mnt
  #mkdir -p /mnt/data
  #mount /dev/${host}/data /mnt/data
  #mount --rbind /boot /mnt/boot
  ####^^^
  mkdir -p /mnt/sys /mnt/proc /mnt/dev /mnt/run /mnt/tmp /mnt/gnu /mnt/var/guix /mnt/gnu/store /mnt/root
  mkdir -p /gnu /var/guix

  mount --rbind /sys /mnt/sys
  mount --rbind /sys /mnt/sys
  mount --rbind /proc /mnt/proc
  mount --rbind /dev /mnt/dev
  mount --rbind /run /mnt/run
  #mount --rbind /tmp /mnt/tmp
  mount -t tmpfs tmpfs /mnt/tmp

  mount --bind /mnt/gnu /gnu
  mount --bind /mnt/var/guix /var/guix
  #mount --bind /mnt/root /root
  #mount --bind /mnt/boot /boot

  cp /etc/ssh/*key* /etc/ssh/
  service ssh start

  groupadd --system guixbuild
  for i in $(seq -w 1 10); do
    useradd -g guixbuild -G guixbuild \
            -d /var/empty -s "$(which nologin)" \
            -c "Guix build user $i" --system \
            "guixbuilder${i}";
  done
  #im guix-daemon --build-users-group=guixbuild &
  guix-daemon --build-users-group=guixbuild &
  )
}

mf () {
  PATH=/run/setuid-programs:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/bin:/sbin PSX="mnt " HOME=/home/fare chroot /mnt zsh
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
