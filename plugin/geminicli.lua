-- Auto-load geminicli.nvim plugin
-- This file is automatically loaded by Neovim when the plugin is installed

if vim.g.loaded_geminicli then
  return
end
vim.g.loaded_geminicli = 1

-- Check if running in headless mode for MCP server
if vim.fn.has("nvim-0.9") == 0 then
  vim.notify("geminicli.nvim requires Neovim 0.9.0 or higher", vim.log.levels.ERROR)
  return
end

-- Auto-setup with defaults if not already configured
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only auto-setup if not already initialized
    local ok, geminicli = pcall(require, "geminicli")
    if ok and not geminicli.state.initialized then
      -- Check if user has a config
      local has_config = false
      
      -- Try to detect if user has called setup in their config
      -- This is a simple heuristic - users should call setup() explicitly
      if not has_config then
        geminicli.setup()
      end
    end
  end,
})