# 🚀 Dotfiles de Manel Romero

Repositorio privado de configuración de entorno para Arch Linux (Wayland / Niri compositor).

Gestionado mediante el patrón **Bare Git Repository**, lo que permite mantener cada archivo en su ruta natural en `$HOME` sin necesidad de enlaces simbólicos (symlinks) ni herramientas externas.

---

## 🛡️ Arquitectura de Seguridad y Privacidad

Para evitar la fuga accidental de credenciales, tokens o información sensible:
1. **Configuración Local Separada (`*.local`)**:
   - `~/.gitconfig`: Carga automáticamente `~/.gitconfig.local` (donde reside el nombre y email).
   - `~/.zshrc`: Carga automáticamente `~/.zshrc.local` si existe (para tokens de API, variables de entorno privadas o rutas específicas de una máquina).
2. **Archivos Críticos Ignorados (`.gitignore`)**:
   - Claves SSH (`~/.ssh/`), GPG (`~/.gnupg/`), contraseñas (`~/.password-store/`).
   - Tokens y sesiones activas (`gh/hosts.yml`, Slack, Spotify, etc.).
   - Historiales de comandos (`.zsh_history`, `.bash_history`).
3. **Auditor de Seguridad Incluido (`dotfiles-doctor`)**:
   - Script en `~/.local/bin/dotfiles-doctor` para verificar en cualquier momento que no se hayan añadido archivos privados ni tokens a Git.

---

## ⚙️ Uso Diario

El alias `dotfiles` está configurado en `~/.zshrc` y `~/.bashrc`:
```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
```

### Comandos habituales:
```bash
# Ver estado de los archivos trackeados (los no trackeados se ignoran)
dotfiles status

# Añadir un archivo de configuración modificado
dotfiles add ~/.config/nvim/init.lua

# Comprobar que no hay secretos antes de comitear
dotfiles-doctor

# Hacer commit y subir cambios
dotfiles commit -m "feat(nvim): actualizar plugins"
dotfiles push
```

---

## 📦 Instalación y Restauración Automatizada

En un nuevo equipo (o tras formatear), puedes restaurar todo el entorno automáticamente ejecutando:

```bash
curl -fsSL https://raw.githubusercontent.com/Manel-Romero/dotfiles/main/install-dotfiles.sh | bash
# O clonando manualmente el bare repo:
git clone --bare https://github.com/Manel-Romero/dotfiles.git $HOME/.dotfiles.git
bash $HOME/install-dotfiles.sh
```

El script `install-dotfiles.sh`:
1. Clona el repositorio bare si no existe.
2. Hace backup automático de cualquier archivo preexistente en `~/.dotfiles-backup-<timestamp>/` para evitar colisiones.
3. Despliega los archivos en `$HOME`.
4. Configura `status.showUntrackedFiles no`.
5. Genera plantillas seguras con permisos `600` para `~/.gitconfig.local` y `~/.zshrc.local`.
6. Compila utilidades necesarias (como `bat_power.c` para Waybar).
7. Ejecuta el chequeo de seguridad final con `dotfiles-doctor`.

---

## 📁 Componentes Incluidos

- **Shell & Terminal:** Zsh (Oh My Zsh, plugins, zoxide, fzf, thefuck), Kitty, Tmux.
- **Entorno de Escritorio Wayland:** Niri compositor, Waybar, SwayNC, Fuzzel.
- **Desarrollo:** Neovim (LazyVim custom), Git, Yazi, Btop, Fastfetch, MPV.
- **Scripts:** `dotfiles-doctor`, `w-disc`, `cliphist-init.sh`, `wallpaper-picker.sh`.
