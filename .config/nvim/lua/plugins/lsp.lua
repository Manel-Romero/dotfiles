return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup({
        ui = { border = "rounded" },
      })

      -- Servidores que Mason descargará y gestionará en Arch
      local mason_servers = {
        "pyright",
        "clangd",
        "rust_analyzer",
        "gopls",
        "bashls",
        "ts_ls",
        "cssls",
        "html",
        "sqlls",
        "jsonls",
        "yamlls",
      }

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Diagnósticos limpios en gutter y texto virtual
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Keymaps universales cuando cualquier LSP se vincula a un archivo
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          local map = vim.keymap.set

          opts.desc = "Ir a definición"
          map("n", "gd", vim.lsp.buf.definition, opts)

          opts.desc = "Ir a implementación"
          map("n", "gi", vim.lsp.buf.implementation, opts)

          opts.desc = "Referencias"
          map("n", "gr", vim.lsp.buf.references, opts)

          opts.desc = "Hover documentación/tipos"
          map("n", "K", vim.lsp.buf.hover, opts)

          opts.desc = "Firma de función"
          map("n", "<C-k>", vim.lsp.buf.signature_help, opts)

          opts.desc = "Renombrar símbolo"
          map("n", "<leader>rn", vim.lsp.buf.rename, opts)

          opts.desc = "Acciones de código"
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

          opts.desc = "Diagnóstico anterior"
          map("n", "[d", vim.diagnostic.goto_prev, opts)

          opts.desc = "Siguiente diagnóstico"
          map("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })

      -- Configuraciones personalizadas por servidor
      local server_configs = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--fallback-style=llvm",
          },
        },
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = { command = "clippy" },
            },
          },
        },
        gopls = {
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              staticcheck = true,
            },
          },
        },
        jsonls = {
          settings = {
            json = {
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = true },
            },
          },
        },
      }

      -- Lista unificada con Haskell (HLS se ejecuta desde GHCup en Arch)
      local all_servers = vim.list_extend(vim.deepcopy(mason_servers), { "hls" })

      -- Registro nativo Neovim 0.11+ sin intermediarios deprecados
      for _, server in ipairs(all_servers) do
        local cfg = {
          capabilities = capabilities,
        }

        if server_configs[server] then
          cfg = vim.tbl_deep_extend("force", cfg, server_configs[server])
        end

        if server == "hls" then
          cfg.filetypes = { "haskell", "lhaskell", "cabal" }
          cfg.settings = {
            haskell = {
              formattingProvider = "ormolu",
              checkProject = true,
            },
          }
        end

        vim.lsp.config[server] = cfg
        vim.lsp.enable(server)
      end

      -- Mason se asegura de tener instalados los binarios necesarios
      require("mason-lspconfig").setup({
        ensure_installed = mason_servers,
        automatic_installation = true,
      })
    end,
  },
}
