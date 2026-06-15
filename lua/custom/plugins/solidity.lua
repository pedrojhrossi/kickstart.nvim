-- Solidity and Blockchain Development Setup for Neovim
-- This file is automatically loaded by custom/plugins/init.lua and runs after the main init.lua configuration

-- Prepend ~/.foundry/bin to PATH so Neovim and the LSP can locate the forge toolchain in a cross-platform way
local is_windows = vim.fn.has('win32') == 1
local path_sep = is_windows and ';' or ':'
local foundry_bin = vim.fn.expand('~/.foundry/bin')
if vim.fn.isdirectory(foundry_bin) == 1 then
  vim.env.PATH = foundry_bin .. path_sep .. vim.env.PATH
end

-- 1. Ensure nomicfoundation-solidity-language-server is installed via Mason
local registry_status, registry = pcall(require, 'mason-registry')
if registry_status then
  pcall(function()
    if not registry.is_installed 'nomicfoundation-solidity-language-server' then
      if #vim.api.nvim_list_uis() > 0 then
        vim.cmd 'MasonInstall nomicfoundation-solidity-language-server'
      end
    end
  end)
end

-- 2. Setup Solidity LSP Server
if vim.lsp.config and vim.lsp.enable then
  -- Neovim 0.11/0.12+ Native LSP API
  vim.lsp.config['solidity_ls_nomicfoundation'] = {}
  vim.lsp.enable('solidity_ls_nomicfoundation')
else
  -- Fallback for Neovim 0.10 and older
  local lspconfig_status, lspconfig = pcall(require, 'lspconfig')
  if lspconfig_status then
    lspconfig.solidity_ls_nomicfoundation.setup({})
  end
end

-- 3. Setup Formatting with conform.nvim
local conform_status, conform = pcall(require, 'conform')
if conform_status then
  -- Register forge_fmt for solidity files
  conform.formatters_by_ft.solidity = { 'forge_fmt' }

  -- Enable auto-formatting on save for Solidity files
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.sol',
    group = vim.api.nvim_create_augroup('solidity-format-on-save', { clear = true }),
    callback = function(args)
      conform.format { bufnr = args.buf, lsp_format = 'fallback' }
    end,
  })
end
