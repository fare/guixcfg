: 'Initialize the metasystem with the following:

mount /dev/mmcblk1p1 /mnt
. /mnt/ia.sh
ini

'

. `dirname "$0"`/modules/common.sh

disk=mmcblk1
host=deepness
part=${disk}p
commoncfg


# Make the deepness image from Yew
mkdeep () {(
  set -x
  cd /home/fare/src/guix/guix-pinephonepro
  GUIX_PROFILE=target/profiles/guix
PULL_EXTRA_OPTIONS=
# --allow-downgrades
PINEPHONE_STORAGE=/dev/XXX

  ./pre-inst-env ${GUIX_PROFILE}/bin/guix \
    system image \
    --image-type=rock64-raw \
    --load-path=/home/fare/src/fare/guixcfg/modules:/home/fare/src/guix/guix-pinephonepro/src \
    --target="aarch64-linux-gnu" \
    /home/fare/src/fare/guixcfg/deepness.scm
)}
