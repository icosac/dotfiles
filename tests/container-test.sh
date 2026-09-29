#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034  # check() bodies are single-quoted on purpose (eval)
# Runs inside a fresh ubuntu/debian container as root (see .github/workflows/ci.yml):
#   docker run --rm -v "$PWD:/src:ro" ubuntu:22.04 bash /src/tests/container-test.sh
# Creates a sudo user, installs twice, and checks the result is linked and idempotent.
set -euo pipefail
SETUPS="${SETUPS:-ohmyzsh neovim tmux-plugins ssh-keys}"

. /etc/os-release
if [ "$ID" = debian ] && [ "$VERSION_ID" = 10 ]; then
  # buster is EOL: its packages moved to archive.debian.org
  printf '%s\n' "deb http://archive.debian.org/debian buster main" \
    "deb http://archive.debian.org/debian buster-updates main" \
    "deb http://archive.debian.org/debian-security buster/updates main" > /etc/apt/sources.list
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq sudo git curl ca-certificates >/dev/null

useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
cp -r /src /home/tester/dotfiles
chown -R tester: /home/tester/dotfiles
# pre-existing identity must survive the switch to a linked .gitconfig
printf '[user]\n\tname = Test User\n\temail = test@example.invalid\n' > /home/tester/.gitconfig
chown tester: /home/tester/.gitconfig

sudo -iu tester bash -c "cd ~/dotfiles && ./install.sh $SETUPS"
echo "=============== second run (must change nothing) ==============="
out="$(sudo -iu tester bash -c "cd ~/dotfiles && ./install.sh $SETUPS" 2>&1)"
printf '%s\n' "$out"

fail=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
H=/home/tester
check "second run links nothing"    '! grep -qE "linked |backed up|added line" <<<"$out"'
check ".zshrc is a symlink"         '[ "$(readlink $H/.zshrc)" = $H/dotfiles/config/zsh/.zshrc ]'
check ".tmux.conf is a symlink"     '[ -L $H/.tmux.conf ]'
check "nvim config is a symlink"    '[ -L $H/.config/nvim ]'
check "git identity kept"           '[ "$(sudo -iu tester git config user.email)" = test@example.invalid ]'
check "ssh Include appears once"    '[ "$(grep -c "^Include config.d/\*" $H/.ssh/config)" = 1 ]'
check "oh-my-zsh installed"         '[ -f $H/.oh-my-zsh/oh-my-zsh.sh ]'
check "zsh starts cleanly"          '[ -z "$(sudo -iu tester zsh -i -c exit 2>&1 >/dev/null)" ]'
check "PATH has no duplicates"      '[ -z "$(sudo -iu tester zsh -i -c "print -l \$path" | sort | uniq -d)" ]'
check "nvim runs"                   'sudo -iu tester nvim --headless +qa'
check "tmux config loads"           '[ -z "$(sudo -iu tester tmux -f $H/.tmux.conf -L t new-session -d \; kill-server 2>&1)" ]'
exit "$fail"
