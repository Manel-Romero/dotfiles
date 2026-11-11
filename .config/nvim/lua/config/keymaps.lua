local map = vim.keymap.set

-- Navegación fluida entre splits
map("n", "<C-h>", "<C-w>h", { desc = "Mover a split izquierdo" })
map("n", "<C-j>", "<C-w>j", { desc = "Mover a split inferior" })
map("n", "<C-k>", "<C-w>k", { desc = "Mover a split superior" })
map("n", "<C-l>", "<C-w>l", { desc = "Mover a split derecho" })

-- Mover líneas seleccionadas en modo Visual
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover bloque abajo" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover bloque arriba" })

-- Mantener cursor centrado al avanzar páginas o buscar
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Diagnósticos globales
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Ver diagnóstico flotante" })
map("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Lista rápida de diagnósticos" })
