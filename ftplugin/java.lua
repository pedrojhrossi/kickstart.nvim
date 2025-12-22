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
--  3. Debugger & Test Bundles (NEW)
-- =============================================================================
-- This function finds the debug adapters in your Mason folder automatically
local function get_bundles()
  local bundles = {}
  local mason_registry = require 'mason-registry'

  local package_path = mason_path .. '/packages'

  local java_debug_path = package_path .. '/java-debug-adapter'

  -- 1. Check java-debug-adapter
  if vim.fn.isdirectory(java_debug_path) ~= 1 then
    -- Force install if missing (Optional, but helpful)
    -- vim.cmd("MasonInstall java-debug-adapter")
    vim.notify('❌ ERROR: java-debug-adapter not found at: ' .. java_debug_path, vim.log.levels.ERROR)
  else
    local jar_pattern = java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar'
    local found_jars = vim.fn.glob(jar_pattern, true, true) -- true, true returns a table

    if #found_jars == 0 then
      vim.notify('❌ ERROR: No debug jar found in: ' .. java_debug_path, vim.log.levels.ERROR)
    else
      vim.notify('✅ Found Debug Jar: ' .. found_jars[1], vim.log.levels.INFO)
      vim.list_extend(bundles, found_jars)
    end
  end

  --   -- 2. Check java-test
  --   local java_test_path = package_path .. "/java-test"
  --   if vim.fn.isdirectory(java_test_path) == 1 then
  --       local jar_pattern = java_test_path .. "/extension/server/*.jar"
  --       local found_jars = vim.fn.glob(jar_pattern, true, true)
  --       if #found_jars > 0 then
  --           vim.list_extend(bundles, found_jars)
  --       end
  --   end
  --
  -- -- Add the Java Debug Adapter
  -- if mason_registry.is_installed 'java-debug-adapter' then
  --   local java_debug_path = package_path .. '/java-debug-adapter'
  --   -- Use glob to find the jar since version numbers change
  --   local jar_pattern = java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar'
  --   vim.list_extend(bundles, vim.split(vim.fn.glob(jar_pattern), '\n'))
  -- end
  --
  -- -- Add Java Test (for running JUnit tests)
  -- if mason_registry.is_installed 'java-test' then
  --   local java_test_path = package_path .. '/java-test'
  --   local jar_pattern = java_test_path .. '/extension/server/*.jar'
  --   vim.list_extend(bundles, vim.split(vim.fn.glob(jar_pattern), '\n'))
  -- end
  --
  return bundles
end

-- =============================================================================
--  4. Project Root Detection
-- =============================================================================
-- local root_markers = { 'settings.gradle', 'pom.xml', '.git', 'mvnw', 'gradlew' }
local root_markers = { 'settings.gradle', '.git', 'mvnw' }

local function find_project_root()
  return vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
end

-- =============================================================================
--  5. JDTLS Setup & Attach
-- =============================================================================
local config = {
  cmd = {
    jdtls_bin,
    string.format('-javaagent:%s', lombok_jar),
    '-configuration',
    home .. '/.config/jdtls/config',
    '-data',
    home .. '/.config/jdtls/workspace',
  },
  root_dir = find_project_root(),

  -- NEW: Pass the bundles (debug/test jars) to JDTLS
  init_options = {
    bundles = get_bundles(),
  },

  -- 👇 VITAL: This fixes the "Couldn't resolve java executable" error
  settings = {
    java = {
      configuration = {
        runtimes = {
          {
            name = 'JavaSE-21', -- Must match your version
            path = '/home/pye/.sdkman/candidates/java/current',
            default = true,
          },
        },
      },
    },
  },
  on_attach = function(client, bufnr)
    -- 1. Initialize the JDTLS Debugger extension
    require('jdtls').setup_dap { hotcodereplace = 'auto', config_overrides = {} }

    -- 2. Define the "Attach" Config GLOBALLY
    -- This tells nvim-dap: "When I debug Java, ALWAYS use this config."
    -- Notice: SINGLE curly braces inside the list!
    require('dap').configurations.java = {
      {
        type = 'java',
        request = 'attach',
        name = 'Debug (Attach) - Remote',
        hostName = '127.0.0.1',
        port = 5005,
      },
    }

    -- 3. Debug Keymaps
    -- We use dap.continue() because it will now automatically pick up the config we defined above.
    vim.keymap.set('n', '<F5>', function()
      local dap = require 'dap'
      -- If we are already debugging, resume. If not, start the config above.
      dap.continue()
    end, { desc = 'Debug: Start/Continue', buffer = bufnr })

    vim.keymap.set('n', '<F10>', function()
      require('dap').step_over()
    end, { desc = 'Debug: Step Over', buffer = bufnr })
    vim.keymap.set('n', '<F11>', function()
      require('dap').step_into()
    end, { desc = 'Debug: Step Into', buffer = bufnr })
    vim.keymap.set('n', '<leader>b', function()
      require('dap').toggle_breakpoint()
    end, { desc = 'Debug: Toggle Breakpoint', buffer = bufnr })

    -- New Java Class Wizard
    vim.keymap.set('n', '<leader>n', ':JavaNew<CR>', { desc = 'New Java Class', buffer = bufnr })
  end,
}

if config.root_dir then
  require('jdtls').start_or_attach(config)
end

-- =============================================================================
--  6. "Java New" Wizard Logic (NEW)
-- =============================================================================
-- Defines the :JavaNew command to create classes/interfaces/records

local function create_java_element()
  local options = {
    'Class',
    'Interface',
    'Record',
    'Enum',
    'Annotation',
    'Abstract Class',
  }

  vim.ui.select(options, {
    prompt = 'Select Java Type:',
    format_item = function(item)
      local icons = { Class = '☕ ', Interface = ' ', Record = '📼 ', Enum = ' ', Annotation = ' ', ['Abstract Class'] = ' ' }
      return (icons[item] or '') .. item
    end,
  }, function(choice)
    if not choice then
      return
    end

    vim.ui.input({ prompt = 'Name (e.g. Service or dto/User): ' }, function(input)
      if not input or input == '' then
        return
      end

      local current_dir = vim.fn.expand '%:p:h'
      local separator = package.config:sub(1, 1)

      -- Handle Subdirectories (e.g. "dto/User")
      local sub_path = ''
      local class_name = input
      if input:find '/' then
        local last_separator_index = input:match '^.*()/'
        sub_path = input:sub(1, last_separator_index - 1)
        class_name = input:sub(last_separator_index + 1)
      end

      local full_dir = current_dir
      if sub_path ~= '' then
        full_dir = current_dir .. separator .. sub_path
        vim.fn.mkdir(full_dir, 'p')
      end

      -- Calculate Package
      local package_path = full_dir:match 'src/main/java/(.*)' or full_dir:match 'src/test/java/(.*)'
      local package_name = package_path and ('package ' .. package_path:gsub('/', '.') .. ';') or ''

      -- Templates
      local templates = {
        ['Class'] = 'public class %s {\n\n}',
        ['Interface'] = 'public interface %s {\n\n}',
        ['Record'] = 'public record %s() {\n\n}',
        ['Enum'] = 'public enum %s {\n\n}',
        ['Annotation'] = 'public @interface %s {\n\n}',
        ['Abstract Class'] = 'public abstract class %s {\n\n}',
      }

      -- Build Content
      local content = {}
      if package_name ~= '' then
        table.insert(content, package_name)
        table.insert(content, '')
        table.insert(content, '')
      end

      local class_def = string.format(templates[choice], class_name)
      for line in class_def:gmatch '[^\r\n]+' do
        table.insert(content, line)
      end

      local file_path = full_dir .. separator .. class_name .. '.java'

      -- Write File
      local file = io.open(file_path, 'w')
      if file then
        for _, line in ipairs(content) do
          file:write(line .. '\n')
        end
        file:close()
        vim.cmd('edit ' .. file_path)
        vim.notify('Created ' .. class_name, vim.log.levels.INFO)
      end
    end)
  end)
end

vim.api.nvim_create_user_command('JavaNew', create_java_element, {})
