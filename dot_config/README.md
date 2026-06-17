# dotfiles

Fedora 44 / GNOME setup managed with [chezmoi](https://chezmoi.io).

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <your-github-username>
```

---

## Repositories

Enable before installing packages.

### RPM Fusion

```bash
sudo dnf install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
```

### Terra

```bash
sudo dnf install --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
```

### Google Chrome

```bash
sudo dnf install google-chrome-stable
# (this adds the repo automatically)
```

### CachyOS kernel (optional — gaming/low-latency)

```bash
sudo dnf copr enable bieszczaders/kernel-cachyos
sudo dnf copr enable bieszczaders/kernel-cachyos-addons
sudo dnf install kernel-cachyos kernel-cachyos-addons
```

---

## Packages

```bash
sudo dnf install \
  fish eza kitty \
  btop fastfetch \
  yazi mpv rofi \
  neovim \
  zoxide starship \
  bat fzf ripgrep \
  wl-clipboard \
  flatpak gnome-tweaks \
  python3-gobject python3-dbus python3-dbus-next python3-pillow \
  pipx
```

### pywal16

```bash
pipx install pywal16
```

### materialyoucolor

```bash
pip install --user materialyoucolor
```

---

## Wallpaper theme service

Watches GNOME wallpaper changes, generates a Material You 16-colour palette
via `materialyoucolor`, stamps pywal16 templates, and nudges running GTK apps
to reload their CSS.

**Files to add to chezmoi:**

| Source (chezmoi)                                              | Target                                          |
|---------------------------------------------------------------|-------------------------------------------------|
| `dot_local/bin/executable_wallpaper-theme.py`                 | `~/.local/bin/wallpaper-theme.py`               |
| `dot_config/systemd/user/wallpaper-theme.service`             | `~/.config/systemd/user/wallpaper-theme.service`|

**Add them:**

```bash
chezmoi add ~/.local/bin/wallpaper-theme.py
chezmoi add ~/.config/systemd/user/wallpaper-theme.service
```

**Enable after applying dotfiles on a new machine:**

```bash
systemctl --user daemon-reload
systemctl --user enable --now wallpaper-theme.service
```

**Dependencies** (all installed via the package steps above):
`python3-gobject`, `python3-dbus`, `pipx` → `pywal16`, `pip --user` → `materialyoucolor`
