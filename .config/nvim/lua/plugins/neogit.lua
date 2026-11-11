return {
  -- =========================================================================
  -- Diffview: Vistas de diff lado a lado, resolución de conflictos e historial
  -- =========================================================================
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: Abrir diffview" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview: Cerrar diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: Historial archivo actual" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: Historial de commits del repo" },
    },
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
        },
        file_history = {
          layout = "diff2_horizontal",
        },
      },
      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
          folder_status_only = false,
        },
        win_config = {
          position = "left",
          width = 35,
        },
      },
    },
  },

  -- =========================================================================
  -- Neogit: Interfaz interactiva para Git estilo Magit
  -- =========================================================================
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit: Estado / Panel principal" },
      { "<leader>gs", "<cmd>Neogit<cr>", desc = "Neogit: Estado (alias)" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit: Crear commit" },
      { "<leader>gl", "<cmd>Neogit log<cr>", desc = "Neogit: Ver historial (Log)" },
      { "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Neogit: Pull popup" },
      { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Neogit: Push popup" },
      { "<leader>gb", "<cmd>Neogit branch<cr>", desc = "Neogit: Gestión de ramas" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      kind = "tab", -- Abre en una pestaña dedicada para no alterar la disposición de ventanas
      graph_style = "unicode", -- Gráficos de ramas limpios con caracteres Unicode
      process_spinner = true, -- Spinner animado al ejecutar operaciones git en segundo plano
      auto_show_console = false, -- No saltar la consola a menos que falle o se abra con '$'
      auto_close_console = true,
      console_timeout = 2000,
      disable_hint = false, -- Mostrar barra de sugerencias/atajos
      disable_insert_on_commit = "auto", -- Modo normal al editar/amend, insert si está vacío

      -- Resaltado avanzado de sintaxis en diffs
      treesitter_diff_highlight = true, -- Mantiene el resaltado de sintaxis de tu código en los diffs
      word_diff_highlight = true,       -- Resalta con precisión los cambios a nivel de palabra

      highlight = {
        red = "#f38ba8",   -- Rosa suave/coral (sustituye rojos-marrones)
        green = "#a6e3a1", -- Menta/salvia suave (sustituye verdes fluorescentes)
        purple = "#89ddff",
      },

      signs = {
        hunk = { "", "" },
        item = { "", "" },
        section = { "", "" },
      },

      filewatcher = {
        enabled = true,
        interval = 1000,
      },

      commit_editor = {
        kind = "tab",
        show_staged_diff = true,
        staged_diff_split_kind = "split",
        spell_check = true,
      },

      integrations = {
        diffview = true,
        telescope = true,
      },
    },
  },
}
