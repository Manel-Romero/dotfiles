local function load_custom_theme()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
  vim.g.colors_name = "mi_tema"

  local bg, fg = "#181a20", "#e8e8d8"
  local c0, c1, c2, c3, c4, c5, c8 = "#2c4246", "#d45c5b", "#a04f44", "#ee572c", "#3c5c71", "#bf6369", "#785758"
  local hl = function(g, o) vim.api.nvim_set_hl(0, g, o) end

  hl("Normal", { bg = bg, fg = fg })
  hl("NormalFloat", { bg = c0, fg = fg })
  hl("Comment", { fg = c8, italic = true })
  hl("String", { fg = c2 })
  hl("Number", { fg = c3 })
  hl("Function", { fg = c4, bold = true })
  hl("Keyword", { fg = c5, bold = true })
  hl("Type", { fg = c1 })
  hl("Statement", { fg = c5 })
  hl("CursorLine", { bg = c0 })
  hl("LineNr", { fg = c8 })
  hl("CursorLineNr", { fg = c3, bold = true })
  
  -- Diagnósticos
  hl("DiagnosticError", { fg = "#d45c5b" })
  hl("DiagnosticWarn", { fg = "#ee572c" })
  hl("DiagnosticInfo", { fg = "#3c5c71" })
  hl("DiagnosticHint", { fg = "#2c4246" })

  -- =========================================================================
  -- Diff & Git (Neovim nativo, Diffview y Neogit)
  -- =========================================================================
  local diff_add_bg    = "#1e332a" -- Verde bosque/salvia suave oscuro (sin fluorescencias)
  local diff_del_bg    = "#361f26" -- Borgoña / vino suave oscuro (sin marrones turbios)
  local diff_change_bg = "#202a36" -- Azul pizarra tenue para filas modificadas
  local diff_text_bg   = "#334c66" -- Azul acero acentuado para tokens modificados intra-línea

  local git_add_fg     = "#81c784" -- Menta / salvia luminoso legible
  local git_del_fg     = "#f38ba8" -- Rosa / coral suave legible
  local git_mod_fg     = "#7098b0" -- Azul pizarra luminoso
  local filler_fg      = "#484f5c" -- Gris tenue para relleno de diff sin ruido

  -- Grupos nativos de Neovim
  hl("DiffAdd",    { bg = diff_add_bg })
  hl("DiffDelete", { bg = diff_del_bg, fg = git_del_fg })
  hl("DiffChange", { bg = diff_change_bg })
  hl("DiffText",   { bg = diff_text_bg, fg = "#f0f4fc", bold = true })

  -- Resaltado mejorado Diffview
  hl("DiffviewDiffAddAsDelete", { bg = diff_del_bg })
  hl("DiffviewDiffDeleteDim",   { fg = filler_fg, bg = "NONE" })

  -- Sintaxis estándar diff y panel lateral
  hl("diffAdded",   { fg = git_add_fg })
  hl("diffRemoved", { fg = git_del_fg })
  hl("diffChanged", { fg = git_mod_fg })

  hl("DiffviewStatusAdded",         { fg = git_add_fg, bold = true })
  hl("DiffviewStatusUntracked",     { fg = git_add_fg })
  hl("DiffviewStatusDeleted",       { fg = git_del_fg, bold = true })
  hl("DiffviewStatusModified",      { fg = git_mod_fg, bold = true })
  hl("DiffviewStatusRenamed",       { fg = git_mod_fg })
  hl("DiffviewFilePanelInsertions", { fg = git_add_fg, bold = true })
  hl("DiffviewFilePanelDeletions",  { fg = git_del_fg, bold = true })
  hl("DiffviewFilePanelConflicts",  { fg = "#ee572c", bold = true })

  -- Grupos específicos de Neogit (legibilidad clara sin contrastes abrasivos)
  hl("NeogitDiffAdd",              { bg = "#1c2e24", fg = "#a6e3a1" })
  hl("NeogitDiffAddHighlight",     { bg = "#233d2f", fg = "#bbf7b8" })
  hl("NeogitDiffAddCursor",        { bg = "#2c4f3c", fg = "#ffffff", bold = true })
  hl("NeogitDiffAddInline",        { bg = "#35694a", fg = "#ffffff", bold = true })
  hl("NeogitDiffAdditions",        { fg = git_add_fg })

  -- Deletions (vino suave / coral sin rojos oxidados o marrones sucios)
  hl("NeogitDiffDelete",           { bg = "#2d1a20", fg = "#f38ba8" })
  hl("NeogitDiffDeleteHighlight",  { bg = "#3b2029", fg = "#fca5a5" })
  hl("NeogitDiffDeleteCursor",     { bg = "#4b2734", fg = "#ffffff", bold = true })
  hl("NeogitDiffDeleteInline",     { bg = "#632f41", fg = "#ffffff", bold = true })
  hl("NeogitDiffDeletions",        { fg = git_del_fg })

  -- Contexto (líneas no modificadas)
  hl("NeogitDiffContext",          { bg = "NONE",    fg = "#9ca3af" })
  hl("NeogitDiffContextHighlight", { bg = "#1f232d", fg = fg })
  hl("NeogitDiffContextCursor",    { bg = "#2c3345", fg = "#ffffff" })

  -- Encabezados de Hunks y Ficheros
  hl("NeogitHunkHeader",           { bg = "#222938", fg = "#7aa2f7", bold = true })
  hl("NeogitHunkHeaderHighlight",  { bg = "#2c3549", fg = "#89ddff", bold = true })
  hl("NeogitHunkHeaderCursor",     { bg = "#37435f", fg = "#ffffff", bold = true })

  hl("NeogitDiffHeader",           { bg = "#222938", fg = "#82aaff", bold = true })
  hl("NeogitDiffHeaderHighlight",  { bg = "#2c3549", fg = "#ffcb6b", bold = true })
end

load_custom_theme()
