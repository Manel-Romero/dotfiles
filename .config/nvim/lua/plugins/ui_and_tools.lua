return {
  -- Explorador de archivos
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Abrir/Cerrar Neo-tree" },
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },

  -- Buscador fuzzy
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar archivos" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Buscar texto" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Ver buffers abiertos" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Listar diagnósticos" },
    },
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- Cierre automático de paréntesis, comillas, etc.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Manipulación de envolventes (parentesis, comillas, tags)
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- Comentarios rápidos
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- Visualización y alineación de CSVs
  {
    "cameron-wags/rainbow_csv.nvim",
    ft = { "csv", "tsv", "csv_semicolon", "csv_whitespace", "csv_pipe" },
    config = true,
  },
}
