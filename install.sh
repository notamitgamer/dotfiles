#!/usr/bin/env bash
# Restore my setup on a fresh Arch install (run in a GNOME session, as your normal user).
#   curl -fsSL https://raw.cdn.amit.is-a.dev/notamitgamer/dotfiles/install.sh | bash
set -euo pipefail

CDN="https://raw.cdn.amit.is-a.dev/notamitgamer/dotfiles"
DOT="$HOME/.dotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root."; exit 1; }
command -v pacman >/dev/null || { echo "This script is for Arch Linux."; exit 1; }

# copy src -> dst, keeping any existing dst as a .bak-<timestamp>
put() {
  local src="$1" dst="$2"
  [ -e "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then mv "$dst" "$dst.bak-$STAMP"; fi
  cp -a "$src" "$dst"
}

say "Downloading dotfiles"
rm -rf "$DOT.new"; mkdir -p "$DOT.new"
curl -fsSL "$CDN/dotfiles.tar.gz" | tar -xz -C "$DOT.new"
rm -rf "$DOT"; mv "$DOT.new" "$DOT"
cd "$DOT"

say "Packages (pacman)"
sudo pacman -Syu --needed --noconfirm
pkgs="$(tr '\n' ' ' < packages/pacman.txt)"
# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $pkgs || {
  warn "bulk install failed, retrying one by one"
  for p in $pkgs; do sudo pacman -S --needed --noconfirm "$p" || warn "skipped $p"; done
}

if ! command -v yay >/dev/null; then
  say "Installing yay (AUR helper)"
  tmp="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi
say "AUR packages"
for p in $(cat packages/aur.txt); do yay -S --needed --noconfirm "$p" || warn "AUR skipped $p"; done

say "pipx tools"
export PATH="$HOME/.local/bin:$PATH"
pipx ensurepath >/dev/null 2>&1 || true
for p in $(cat packages/pipx.txt); do pipx install "$p" || warn "pipx skipped $p"; done

say "npm global tools"
npm config set prefix "$HOME/.local"
for p in $(cat packages/npm.txt); do npm install -g "$p" || warn "npm skipped $p"; done

say "zsh + oh-my-zsh + git"
[ -d "$HOME/.oh-my-zsh" ] || git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
put config/.zshrc "$HOME/.zshrc"
put config/.gitconfig "$HOME/.gitconfig"
if [ "$(basename "${SHELL:-}")" != zsh ]; then
  chsh -s "$(command -v zsh)" || warn "run manually: chsh -s $(command -v zsh)"
fi

say "App configs"
put config/alacritty.toml "$HOME/.config/alacritty/alacritty.toml"
put config/fonts.conf     "$HOME/.config/fontconfig/fonts.conf"
put config/starship.toml  "$HOME/.config/starship.toml"
put config/nvim           "$HOME/.config/nvim"
put config/micro          "$HOME/.config/micro"
put config/gtk-3.0        "$HOME/.config/gtk-3.0"
put config/gtk-4.0        "$HOME/.config/gtk-4.0"
put config/vscode/settings.json "$HOME/.config/Code/User/settings.json"
put config/vscode/snippets      "$HOME/.config/Code/User/snippets"
put wallpapers/background "$HOME/.config/background"
mkdir -p "$HOME/.local/bin"
for f in bin/*; do
  if [ -f "$f" ]; then cp -a "$f" "$HOME/.local/bin/"; chmod +x "$HOME/.local/bin/$(basename "$f")"; fi
done

say "Fonts"
fc-cache -f >/dev/null 2>&1 || true
if ! fc-list | grep -qi "comic code"; then
  warn "Comic Code is a paid font and is not in this repo. Copy its .otf files to ~/.local/share/fonts/ then run: fc-cache -f"
fi

say "Theme and icons"
mkdir -p "$HOME/.themes" "$HOME/.local/share/icons"
[ -d themes/ColdMetal-NoLogo ] && cp -a themes/ColdMetal-NoLogo "$HOME/.themes/"
if [ ! -d "$HOME/.local/share/icons/Tela-manjaro-dark" ]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 https://github.com/vinceliuice/Tela-icon-theme.git "$tmp/tela"
  (cd "$tmp/tela" && ./install.sh manjaro) || warn "Tela icon install failed"
  rm -rf "$tmp"
fi

say "GNOME extensions"
if command -v gext >/dev/null && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  while read -r uuid; do
    if [ -n "$uuid" ]; then gext install "$uuid" || warn "extension skipped: $uuid"; fi
  done < gnome/extensions.txt
else
  warn "Not in a GNOME session (or gext missing). Log in to GNOME and re-run this script."
fi

say "GNOME settings (dconf)"
for f in gnome/*.dconf; do
  b="$(basename "$f" .dconf)"
  case "$b" in
    ext_*) path="/org/gnome/shell/extensions/${b#ext_}/" ;;
    shell) path="/org/gnome/shell/" ;;
    *)     path="/org/gnome/$(echo "$b" | tr _ /)/" ;;
  esac
  dconf load "$path" < "$f" || warn "dconf failed for $path"
done

say "VS Code extensions"
if command -v code >/dev/null; then
  while read -r ext; do
    [ -n "$ext" ] || continue
    code --install-extension "$ext" --force >/dev/null 2>&1 || warn "extension skipped: $ext"
  done < packages/vscode-extensions.txt
fi

say "Done. Still manual:"
echo " - gh auth login, and restore your SSH/GPG keys from your private backup"
echo " - Comic Code font, Obsidian vault, Firefox Sync sign-in"
echo " - Log out and back in so the shell, theme and extensions all apply"
