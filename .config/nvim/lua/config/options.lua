local opt = vim.opt

-- Numeración
opt.number = true
opt.relativenumber = true -- Alternado a true para saltos rápidos con count

-- Indentación y tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = false

-- Búsqueda
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Rendimiento y UI
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitbelow = true
opt.splitright = true
opt.clipboard = "unnamedplus" -- Sincronización con portapapeles del sistema

-- Archivos de respaldo
opt.swapfile = false
opt.backup = false
opt.undofile = true -- Historial de deshacer persistente entre sesiones
