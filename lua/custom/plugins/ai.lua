-- AI Integrations: claudecode.nvim and Antigravity CLI (agy)
-- This file is located under lua/custom/plugins/ai.lua to avoid upstream conflicts

local gh = _G.gh or function(repo) return 'https://github.com/' .. repo end

-- 1. Install claudecode.nvim plugin
vim.pack.add { gh 'coder/claudecode.nvim' }

local status, claudecode = pcall(require, 'claudecode')
if status then
  claudecode.setup {
    -- You can add custom configuration for claudecode.nvim here if needed
  }
end

-- 2. Antigravity Terminal Toggle Logic
local antigravity_buf = nil
local antigravity_win = nil

local function toggle_antigravity()
  -- If the window exists and is valid, close it
  if antigravity_win and vim.api.nvim_win_is_valid(antigravity_win) then
    vim.api.nvim_win_close(antigravity_win, true)
    antigravity_win = nil
    return
  end

  -- If the buffer exists and is valid, reopen the window
  if antigravity_buf and vim.api.nvim_buf_is_valid(antigravity_buf) then
    vim.cmd('botright vertical split')
    antigravity_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(antigravity_win, 65)
    vim.api.nvim_win_set_buf(antigravity_win, antigravity_buf)
    vim.cmd('startinsert')
    return
  end

  -- Otherwise, create a new vertical terminal split and run `agy`
  vim.cmd('botright vertical split')
  antigravity_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(antigravity_win, 65)
  vim.cmd('term agy')
  antigravity_buf = vim.api.nvim_get_current_buf()
  
  -- Set buffer options for clean terminal appearance
  vim.api.nvim_buf_set_name(antigravity_buf, 'Antigravity CLI')
  vim.cmd('startinsert')
end

-- 3. Install Claude Code Helper
local function install_claude_code()
  vim.cmd('botright split')
  local win = vim.api.nvim_get_current_win()
  vim.cmd('term curl -fsSL https://claude.ai/install.sh | bash')
  vim.cmd('startinsert')
end

-- 4. Unified AI Menu Keymap
vim.keymap.set('n', '<leader>ai', function()
  local items = {
    '1. Antigravity: Open/Toggle CLI (agy)',
    '2. Claude Code: Start Session',
    '3. Claude Code: Open Panel',
    '4. Claude Code: Focus Panel',
    '5. Claude Code: Add Current File',
    '6. Claude Code: Stop Session',
    '7. System: Install/Update Claude Code CLI',
  }
  vim.ui.select(items, {
    prompt = 'Select AI Assistant Action:',
  }, function(choice)
    if not choice then return end
    if choice:match('1%.') then
      toggle_antigravity()
    elseif choice:match('2%.') then
      vim.cmd('ClaudeCodeStart')
    elseif choice:match('3%.') then
      vim.cmd('ClaudeCodeOpen')
    elseif choice:match('4%.') then
      vim.cmd('ClaudeCodeFocus')
    elseif choice:match('5%.') then
      vim.cmd('ClaudeCodeAdd')
    elseif choice:match('6%.') then
      vim.cmd('ClaudeCodeStop')
    elseif choice:match('7%.') then
      install_claude_code()
    end
  end)
end, { desc = '[A]I [I]ntegration Menu' })
