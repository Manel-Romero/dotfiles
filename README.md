# Dotfiles

Mis archivos de configuración para Arch Linux (Wayland con Niri).

Están gestionados como un **Bare Git Repo** (`~/.dotfiles.git`) con **sparse-checkout**. Esto permite:
- Tener los archivos en su ruta normal en `$HOME` (sin symlinks ni programas extra).
- Elegir qué módulos instalar según el equipo (modular).
- Que `git status` solo muestre los archivos configurados, sin ensuciarse con el resto de cosas de tu `$HOME`.

---

## Instalación en un equipo nuevo

### 1. Menú interactivo
```bash
curl -fsSL https://raw.githubusercontent.com/Manel-Romero/dotfiles/main/install-dotfiles.sh | bash
```

### 2. Usando perfiles rápidos
```bash
# Básico para servidores o terminal (shell + git + core)
./install-dotfiles.sh --profile=minimal

# Entorno de desarrollo sin entorno gráfico (shell, git, kitty, neovim, utilidades CLI)
./install-dotfiles.sh --profile=dev

# Todo el escritorio completo
./install-dotfiles.sh --profile=desktop
```

### 3. Instalar módulos sueltos
Las dependencias se resuelven solas (por ejemplo, si pides `nvim`, te incluye `git` y `shell` automáticamente):
```bash
# Solo Neovim y lo que necesita
./install-dotfiles.sh --modules=nvim

# Solo Waybar y el entorno de escritorio
./install-dotfiles.sh --modules=waybar

# Añadir un módulo a lo que ya tienes instalado (sin borrar el resto)
./install-dotfiles.sh --add-module=cli-tools

# Simular qué se instalaría sin tocar nada (dry-run)
./install-dotfiles.sh --modules=waybar --dry-run

# Instalar también los paquetes del sistema en Arch (pacman/yay)
./install-dotfiles.sh --profile=desktop --packages
```

---

## Módulos disponibles

| Módulo | Prerrequisitos | Qué incluye | Paquetes de Arch |
| :--- | :--- | :--- | :--- |
| `core` | ninguno | .gitignore, instalador, dotfiles-doctor, plantillas .local | base-devel, git |
| `git` | core | .gitconfig | git, github-cli |
| `shell` | core, git | .bashrc, .zshrc, .zprofile, .tmux.conf, funciones zsh | zsh, tmux, zoxide, fzf, thefuck |
| `terminal` | shell | kitty | kitty, ttf-jetbrains-mono-nerd |
| `system` | core | wireplumber, portales xdg, directorios de usuario | xdg-desktop-portal-wlr, wireplumber, pipewire |
| `desktop` | system, terminal | niri, swaync, fuzzel, wallpapers | niri, swaybg, swaync, fuzzel, cliphist, wl-clipboard |
| `waybar` | desktop | waybar y bat_power (se compila solo) | waybar, gcc |
| `nvim` | git, shell | configuración de Neovim (LazyVim) | neovim, ripgrep, fd |
| `cli-tools` | shell | yazi, btop, fastfetch, mpv, thefuck, w-disc | yazi, btop, fastfetch, mpv |

---

## Uso en el día a día

Usa el alias `dotfiles` (ya viene en tu `.zshrc` y `.bashrc`):

```bash
# Ver qué archivos has modificado
dotfiles status

# Añadir un archivo modificado
dotfiles add ~/.config/nvim/lua/config/keymaps.lua

# Comprobar que no hay contraseñas ni claves privadas antes de subir
dotfiles-doctor

# Guardar cambios y subir a GitHub
dotfiles commit -m "cambios en nvim"
dotfiles push
```

---

## Seguridad y privacidad

Para evitar subir contraseñas o datos personales por error:

1. **Archivos `.local` (ignorados por Git)**:
   - `~/.gitconfig.local`: Aquí van tu nombre y email.
   - `~/.zshrc.local`: Aquí van tus tokens de API, variables secretas o rutas propias de este equipo.
2. **Filtro de `.gitignore`**:
   - Bloquea `.ssh/`, `.gnupg/`, contraseñas (`pass`), historiales de terminal (`.zsh_history`), tokens de GitHub CLI y cookies de sesión (Slack, Spotify, UPV).
3. **Auditor `dotfiles-doctor`**:
   - Puedes ejecutar `dotfiles-doctor` cuando quieras. Revisa que no haya archivos privados trackeados ni tokens o claves privadas en el contenido antes de hacer commit.
