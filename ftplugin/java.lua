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
-- Only include the actual plugin JARs, not all dependencies
local bundles = {}
local debug_bundle = vim.fn.glob(mason_path .. '/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', true)
if debug_bundle ~= '' then
  table.insert(bundles, debug_bundle)
end

local test_bundles = vim.fn.glob(mason_path .. '/packages/java-test/extension/server/com.microsoft.java.test.plugin-*.jar', true)
if test_bundles ~= '' then
  vim.list_extend(bundles, vim.split(test_bundles, '\n'))
end

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
      extendedClientCapabilities = require('jdtls').extendedClientCapabilities,
    },
    on_attach = function(client, bufnr)
      -- Enable DAP (Debugging)
      local jdtls = require 'jdtls'
      jdtls.setup_dap { hotcodereplace = 'auto' }
      require('jdtls.dap').setup_dap_main_class_configs()

      -- Manual fallback configuration if automatic discovery fails
      local dap = require 'dap'
      dap.configurations.java = dap.configurations.java or {}
      table.insert(dap.configurations.java, {
        type = 'java',
        request = 'launch',
        name = 'Launch (Manual)',
        mainClass = function()
          return coroutine.create(function(dap_co)
            vim.ui.input({ prompt = 'Main Class: ' }, function(input) coroutine.resume(dap_co, input) end)
          end)
        end,
      })

      -- Set up keymaps for Java specifically if needed
      local map = function(keys, func, desc)
        if func then
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Java: ' .. desc })
        end
      end

      map('<leader>co', jdtls.organize_imports, '[C]ode [O]ptimize Imports')
      map('<leader>df', jdtls.test_nearest_method, '[D]ebug [F]unction (Test)')
      map('<leader>dc', jdtls.test_class, '[D]ebug [C]lass (Test)')
    end,
  }

  require('jdtls').start_or_attach(config)
end
