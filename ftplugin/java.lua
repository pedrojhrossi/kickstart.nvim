-- =============================================================================
--  1. Standard Configuration
-- =============================================================================
-- Set the standard 4-space indentation for Java files
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true
vim.bo.softtabstop = 4

-- =============================================================================
--  2. Paths & Dependencies
-- =============================================================================
local home = os.getenv 'HOME'
local mason_path = vim.fn.stdpath 'data' .. '/mason'
local jdtls_bin = mason_path .. '/bin/jdtls'
-- Note: The path to lombok.jar is typically within the jdtls package directory in mason.
local lombok_jar = mason_path .. '/packages/jdtls/lombok.jar'

-- =============================================================================
--  3. Debugging & Testing Bundles
-- =============================================================================
local bundles = {}
local java_debug_path = mason_path .. '/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
vim.list_extend(bundles, vim.split(vim.fn.glob(java_debug_path), '\n'))

local java_test_path = mason_path .. '/packages/java-test/extension/server/*.jar'
vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path), '\n'))

-- =============================================================================
--  4. Project Root Detection
-- =============================================================================
local root_markers = { 'gradlew', '.git', 'mvnw' }
local project_root = vim.fs.root(0, root_markers)

-- =============================================================================
--  5. JDTLS Configuration
-- =============================================================================
if project_root then
  local cmd = {
    jdtls_bin,
    string.format('-javaagent:%s', lombok_jar),
    '-configuration',
    home .. '/.cache/jdtls/config',
    '-data',
    home .. '/.cache/jdtls/workspace/' .. vim.fn.fnamemodify(project_root, ':p:h:t'),
  }

  local config = {
    cmd = cmd,
    root_dir = project_root,
    init_options = {
      bundles = bundles,
    },
    on_attach = function(client, bufnr)
      -- Enable DAP (Debugging)
      require('jdtls').setup_dap { hotcodereplace = 'auto' }
      -- Enable DAP UI Main Class discovery
      require('jdtls.dap').setup_dap_main_class_configs()
      
      -- Set up keymaps for Java specifically if needed
      local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Java: ' .. desc })
      end
      
      map('<leader>co', require('jdtls').optimize_imports, '[C]ode [O]ptimize Imports')
    end,
  }

  require('jdtls').start_or_attach(config)
end
