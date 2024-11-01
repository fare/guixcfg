. `dirname "$0"/common.sh`

# https://guix.gnu.org/manual/devel/en/html_node/Chrooting-into-an-existing-system.html

mdsk () {
  cryptsetup luksOpen /dev/nvme0n1p2 luna.crypt
  vgchange -ay
  mount /dev/luna/root /mnt
  mount /dev/luna/alt /mnt/nixos
  mount /dev/nvme0n1p1 /mnt/boot
}

exit 0

### ORGANIZE WHAT'S BELOW

export HOME=/home/fare ZDOTDIR=/home/fare PSX="Luna " PATH=/home/fare/bin:/home/fare/bin/nix:/home/fare/etc/bin:/home/fare/.nix-profile/bin:/home/fare/.nix-profile/sbin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/run/current-system/sw/bin:/run/current-system/sw/sbin:/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/sw/sbin:/home/fare/.config/guix/current/bin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin

chroot /mnt /var/guix/profiles/system/profile/bin/zsh

guix-daemon --build-users-group=guixbuild --disable-chroot &

guix system reconfigure --load-path=/home/fare/src/fare/guixcfg/modules /home/fare/src/fare/guixcfg/mew.scm /home/fare/src/fare/guixcfg/luna.scm


mount --rbind /sys /mew/sys
mount --rbind /proc /mew/proc
mount --rbind /dev /mew/dev
mount --rbind /run /mew/run
export HOME=/home/fare ZDOTDIR=/home/fare PSX="Mew " PATH=/home/fare/bin:/home/fare/bin/nix:/home/fare/etc/bin:/home/fare/.nix-profile/bin:/home/fare/.nix-profile/sbin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/run/current-system/sw/bin:/run/current-system/sw/sbin:/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/sw/sbin:/home/fare/.config/guix/current/bin:/var/guix/profiles/system/profile/bin:/var/guix/profiles/system/profile/sbin
