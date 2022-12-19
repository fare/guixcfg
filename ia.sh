: 'Initialize the metasystem with the following:

mount /dev/mmcblk1p1 /mnt
. /mnt/ia.sh
ini

'

disk=sda
host=mew
part=${disk}
#part=${disk}p
bootpart=${part}1
cryptpart=${part}2

### Code below

inimnt () {
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
  mkdir -p /mnt/sys /mnt/proc /mnt/dev /mnt/run /mnt/tmp /mnt/gnu /mnt/var/guix /mnt/gnu/store /mnt/root
  mkdir -p /gnu /var/guix

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
  PATH=/run/setuid-programs:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin:/bin:/sbin PSX="mnt " HOME=/home/fare chroot /mnt zsh
}

aip () {
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

##
yew_hacks () {
  mount --bind /sys /guix/sys
  mount --bind /proc /guix/proc
  mount --bind /dev /guix/dev
  mount --bind /dev/pts /guix/dev/pts
  mount --bind /run /guix/run
  #mount -t tmpfs tmpfs /guix/tmp
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

  guix system reconfigure --load-path=/home/fare/src/fare/guixcfg/modules /home/fare/src/fare/guixcfg/yew.scm
  cp /boot/grub/grub.cfg /boot/grub/grub.cfg.guix
}

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
  guix system reconfigure --load-path=/home/fare/src/fare/guixcfg/modules /home/fare/src/fare/guixcfg/mew.scm
  cp /boot/grub/grub.cfg /boot/grub/grub.cfg.guix

  namekill guix-daemon
  for i in /boot /mnt/boot /mnt/tmp /mnt/run/user/1000/gvfs /mnt/run/user/1000 /mnt/run/wrappers /mnt/run/keys /mnt/run /mnt/dev/mqueue /mnt/dev/hugepages /mnt/dev/shm /mnt/dev/pts /mnt/dev /mnt/proc /mnt/sys/fs/pstore /mnt/sys/kernel/config /mnt/sys/fs/fuse/connections /mnt/sys/kernel/debug /mnt/sys/fs/bpf /mnt/sys/firmware/efi/efivars /mnt/sys/fs/cgroup /mnt/sys/kernel/security /mnt/sys /gnu /guix/var/guix /mnt/nixos /mnt ; do umount $i ; done

}

luna_hacks () {
    cryptsetup luksOpen /dev/nvme0n1p2 luna ; vgchange -ay
    mkdir -p /luna ; mount /dev/luna/alt /luna ; mount /dev/luna/root /luna/guix ; mount /dev/nvme0n1p1 /luna/boot
}
