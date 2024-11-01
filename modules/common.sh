### Common configuration

commoncfg () {
  bootpart=${part}1
  cryptpart=${part}2
}

### Code below

decrypt () {
  umount /mnt
  cryptsetup luksOpen /dev/${cryptpart} ${host}.crypt
  vgchange -ay
  swapon /dev/mapper/${host}-swap
  ####vvv
  mount /dev/${host}/guix /mnt
  mount /dev/${host}/nixos /mnt/nixos
  mount /dev/${bootpart} /mnt/boot
  ###
  #mount /dev/${host}/pinephone /mnt
  #mkdir -p /mnt/data
  #mount /dev/${host}/data /mnt/data
  #mount --rbind /boot /mnt/boot
  ####^^^
}

inimnt2 () {
  mkdir -p /mnt/sys /mnt/proc /mnt/dev /mnt/run /mnt/tmp /mnt/root
  mkdir -p /mnt/var/guix /mnt/gnu/store /mnt/var/run
  mkdir -p /gnu /var/guix /var/run

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
}

inicfg () {
  cp /mnt/home/fare/etc/term/screenrc /root/.screenrc
  cp /mnt/etc/ssh/*key* /etc/ssh/
  groupadd --system guixbuild
  for i in $(seq -w 1 10); do
    useradd -g guixbuild -G guixbuild \
            -d /var/empty -s "$(which nologin)" \
            -c "Guix build user $i" --system \
            "guixbuilder${i}";
  done
}

iniserv () {
  service ssh start
  #im guix-daemon --build-users-group=guixbuild &
  guix-daemon --build-users-group=guixbuild &
}

ini () { (set -x; inimnt; inimnt2; inicfg; iniserv) }

mf () {
  PATH=/run/setuid-programs:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/usr/local/sbin:/usr/sbin:/sbin:/usr/games:/usr/local/bin:/usr/bin:/bin PSX="mnt " HOME=/home/fare chroot /mnt zsh
}

aip () {
  apt update ; apt install -y emacs screen less zsh btrfs-progs
}

im () {
  HOME=/root
  PATH=/run/setuid-programs:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/usr/local/sbin:/usr/sbin:/sbin:/usr/games:/usr/local/bin:/usr/bin:/bin
  chroot /mnt "$@"
}

f () {
  . /mnt/boot/${host}.sh
}

re () {
  im guix system reconfigure --load-path=/home/fare/src/fare/guixcfg/modules:/home/fare/src/guix/guix-pinephonepro/src /home/fare/src/fare/guixcfg/${host}.scm
}

fix () {
  a=( $(grep /gnu/store /mnt/boot/grub/grub.cfg | grep -v '^#' | sed 's,^\(.*\)\?/gnu/store/\([^ ;]\+\).*$,\2,' | sort -u) )
  mkdir -p /mnt/boot/gnu/store
  ( cd /mnt/gnu/store && rsync -cLRrv --delete $a /mnt/boot/gnu/store/ )
  cp /mnt/boot/grub/grub.cfg /mnt/boot/grub/grub.cfg.bak
  sed 's,^cryptomount,#cryptomount,' < /mnt/boot/grub/grub.cfg.bak > /mnt/boot/grub/grub.cfg
}

### Cross-installation from a system that has a local guix
mount_over_guix () {
  #mount --rbind /sys /mnt/sys
  #mount --rbind /proc /mnt/proc
  #mount --rbind /dev /mnt/dev
  mount --bind /sys /mnt/sys
  mount --bind /proc /mnt/proc
  mount --bind /dev /mnt/dev
  #mount --rbind /run /mnt/run
  #mount -t tmpfs tmpfs /mnt/tmp
  mount --bind /mnt/gnu /gnu
  mount --bind /mnt/var/guix /var/guix
  mount --bind /mnt/boot /boot

  guix-daemon --build-users-group=guixbuild --disable-chroot &
}
