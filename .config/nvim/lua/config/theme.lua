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
end

load_custom_theme()
