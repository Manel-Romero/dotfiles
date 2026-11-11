return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        -- Compilados y de sistemas
        "c", "cpp", "rust", "haskell", "go", "java",
        -- Scripting
        "python", "bash", "lua",
        -- Web
        "javascript", "typescript", "tsx", "html", "css",
        -- Datos y configuración
        "json", "jsonc", "yaml", "toml", "sql", "csv", "markdown", "markdown_inline",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
    },
    config = function(_, opts)
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if ok then
        configs.setup(opts)
      end
    end,
  },
}
