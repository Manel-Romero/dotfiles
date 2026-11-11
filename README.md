# 🚀 Dotfiles de Manel Romero

Repositorio privado de configuración de entorno para Arch Linux (Wayland / Niri compositor).

Gestionado mediante el patrón **Bare Git Repository** con soporte para **instalación modular y sparse-checkout (`--no-cone`)**, lo que permite:
- Mantener cada archivo en su ruta natural en `$HOME` sin enlaces simbólicos rotos.
- Elegir qué componentes instalar de forma modular resolviendo dependencias automáticamente.
- Mantener `dotfiles status` limpio sin ruido de archivos no instalados.

---

## 🛡️ Arquitectura de Seguridad y Privacidad (Zero-Leak)

Para evitar la fuga accidental de credenciales, tokens o información sensible:
1. **Configuración Local Separada (`*.local`)**:
   - `~/.gitconfig`: Carga automáticamente `~/.gitconfig.local` (donde reside el nombre y email).
   - `~/.zshrc`: Carga automáticamente `~/.zshrc.local` si existe (para tokens de API, variables de entorno privadas o rutas de red).
2. **Archivos Críticos Ignorados (`.gitignore`)**:
   - Claves SSH (`~/.ssh/`), GPG (`~/.gnupg/`), contraseñas (`~/.password-store/`).
   - Tokens y sesiones activas (`gh/hosts.yml`, Slack, Spotify, portal UPV).
   - Historiales de terminal (`.zsh_history`, `.bash_history`).
3. **Auditor de Seguridad Incluido (`dotfiles-doctor`)**:
   - Script en `~/.local/bin/dotfiles-doctor` para verificar en cualquier momento que no se hayan añadido archivos privados ni tokens a Git.

---

## 📦 Instalación y Automatización Modular (`install-dotfiles.sh`)

Puedes instalar todo el sistema o seleccionar únicamente los módulos deseados. Las dependencias entre módulos se resuelven automáticamente de forma topológica.

### 1. Instalación Rápida
```bash
# Menú interactivo (elige perfil o módulos individuales):
curl -fsSL https://raw.githubusercontent.com/Manel-Romero/dotfiles/main/install-dotfiles.sh | bash

# O mediante Git:
git clone --bare https://github.com/Manel-Romero/dotfiles.git $HOME/.dotfiles.git
bash $HOME/install-dotfiles.sh
```

### 2. Instalación por Perfiles (Presets)
```bash
# Servidor o entorno mínimo (Shell + Git + Core):
./install-dotfiles.sh --profile=minimal

# Entorno de desarrollo sin GUI (Shell, Git, Kitty, Neovim, CLI tools):
./install-dotfiles.sh --profile=dev

# Entorno completo de escritorio (todos los módulos):
./install-dotfiles.sh --profile=desktop
```

### 3. Selección Modular de Componentes
Si solo necesitas módulos específicos, el instalador resolverá sus dependencias automáticamente:
```bash
# Instala Neovim (incluye automáticamente sus dependencias: core, git, shell):
./install-dotfiles.sh --modules=nvim

# Instala Waybar (incluye: core, git, shell, system, terminal, desktop):
./install-dotfiles.sh --modules=waybar

# Añadir un módulo a una instalación existente sin borrar los actuales:
./install-dotfiles.sh --add-module=cli-tools

# Simular qué archivos y paquetes se instalarían sin tocar el disco:
./install-dotfiles.sh --modules=waybar --dry-run

# Instalar también los paquetes de Arch Linux con pacman/yay:
./install-dotfiles.sh --profile=desktop --packages
```

---

## 🧩 Grafo de Módulos y Dependencias

| Módulo | Prerrequisitos | Archivos / Componentes | Paquetes Arch Linux |
| :--- | :--- | :--- | :--- |
| **`core`** | _ninguno_ | `.gitignore`, `README.md`, `install-dotfiles.sh`, `dotfiles-doctor`, plantillas `.local` | `base-devel`, `git` |
| **`git`** | `core` | `~/.gitconfig` | `git`, `github-cli` |
| **`shell`** | `core`, `git` | `~/.bashrc`, `~/.zshrc`, `~/.zprofile`, `~/.tmux.conf`, `~/.zfunc/_miupv` | `zsh`, `tmux`, `zoxide`, `fzf`, `thefuck` |
| **`terminal`** | `shell` | `~/.config/kitty/` | `kitty`, `ttf-jetbrains-mono-nerd` |
| **`system`** | `core` | `wireplumber`, `xdg-desktop-portal`, `user-dirs`, `mimeapps.list` | `xdg-desktop-portal-wlr`, `wireplumber`, `pipewire` |
| **`desktop`** | `system`, `terminal` | `niri`, `swaync`, `fuzzel`, `Wallpapers/yak.webp` | `niri`, `swaybg`, `swaync`, `fuzzel`, `cliphist`, `wl-clipboard` |
| **`waybar`** | `desktop` | `waybar`, `battery-intel.sh`, `bat_power.c` (autocompilado) | `waybar`, `gcc` |
| **`nvim`** | `git`, `shell` | `~/.config/nvim/` (LazyVim custom) | `neovim`, `ripgrep`, `fd` |
| **`cli-tools`** | `shell` | `yazi`, `btop`, `fastfetch`, `mpv`, `thefuck`, `w-disc` | `yazi`, `btop`, `fastfetch`, `mpv` |

---

## ⚙️ Uso Diario

El alias `dotfiles` está configurado en `~/.zshrc` y `~/.bashrc`:
```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
```

### Comandos habituales:
```bash
# Ver estado de los archivos trackeados
dotfiles status

# Añadir un archivo modificado
dotfiles add ~/.config/nvim/lua/config/keymaps.lua

# Auditar que no haya credenciales ni secretos antes de commitear
dotfiles-doctor

# Hacer commit y subir cambios al repo privado
dotfiles commit -m "feat(nvim): añadir nuevo atajo"
dotfiles push

# Ver qué módulos/rutas están activos en sparse-checkout
dotfiles sparse-checkout list
```
