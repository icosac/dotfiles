#!/usr/bin/env bash
# desc: ROS 2 via Tiryoh's scripts (18.04 dashing, 20.04 foxy, 22.04 humble, 24.04 jazzy); ROS2_PACKAGE=desktop|ros-base
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=lib/os.sh
. "$DOTFILES/lib/os.sh"
refuse_root

case "$OS_ID $OS_VERSION" in
  "ubuntu 18.04") distro=dashing ;;
  "ubuntu 20.04") distro=foxy ;;
  "ubuntu 22.04") distro=humble ;;
  "ubuntu 24.04") distro=jazzy ;;
  *) warn "ROS 2 setup supports Ubuntu 18.04-24.04 only (this is $OS_ID $OS_VERSION), skipping"; exit 0 ;;
esac
distro="${ROS_DISTRO_OVERRIDE:-$distro}"
package="${ROS2_PACKAGE:-desktop}"

vendor="$DOTFILES/vendor/ros2_setup_scripts"
# Only this submodule, not its nested test submodules
[ -f "$vendor/run.sh" ] || run git -C "$DOTFILES" submodule update --init vendor/ros2_setup_scripts
script="$vendor/ros2-$distro-$package-main.sh"
[ -f "$script" ] || die "no upstream script $(basename "$script")"

if [ -f "/opt/ros/$distro/setup.bash" ] && [ "${FORCE:-0}" != 1 ]; then
  ok "ROS 2 $distro already installed (FORCE=1 to re-run)"
else
  warn "the upstream script also runs a full 'apt upgrade'"
  run bash "$script"
fi
ok "in zsh, run 'ros2env' to source ROS 2 $distro (see config/zsh/zshrc.d/60-ros.zsh)"
