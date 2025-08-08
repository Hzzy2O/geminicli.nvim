---@brief [[
--- Gemini CLI Neovim Integration
--- This plugin integrates Google Gemini CLI with Neovim through MCP (Model Context Protocol),
--- enabling AI-assisted coding experiences directly in Neovim.
---@brief ]]

---@module 'geminicli'
local M = {}

local logger = require("geminicli.logger")
local config = require("geminicli.config")
local terminal = require("geminicli.terminal")

--- Plugin version
---@type table
M.version = {
  major = 0,
  minor = 1,
  patch = 0,
  string = function(self)
    return string.format("%d.%d.%d", self.major, self.minor, self.patch)
  end,
}

--- Plugin state
---@type table
M.state = {
  config = {},
  terminal = nil,
  initialized = false,
}

--- Setup the plugin with user configuration
---@param opts table? User configuration options
function M.setup(opts)
  if M.state.initialized then
    logger.warn("geminicli.nvim already initialized")
    return
  end

  -- Merge user config with defaults
  M.state.config = config.merge(opts or {})

  -- Set up logging
  logger.setup(M.state.config.log)

  -- Register commands
  M._register_commands()

  M.state.initialized = true
end

--- Register user commands
function M._register_commands()
  local commands = {
    {
      name = "Gemini",
      callback = function()
        M.open_terminal()
      end,
      opts = { desc = "Open Gemini CLI terminal" },
    },
    {
      name = "GeminiClose",
      callback = function()
        M.close_terminal()
      end,
      opts = { desc = "Close Gemini CLI terminal" },
    },
    {
      name = "GeminiSend",
      callback = function(opts)
        M.send(opts)
      end,
      opts = {
        desc = "Send selection (if any) or a file path (arg or current buffer) to Gemini CLI",
        nargs = "?",
        range = true,
        complete = "file",
      },
    },
    {
      name = "GeminiAdd",
      callback = function(opts)
        M.add_file(opts)
      end,
      opts = {
        desc = "Send current buffer content to Gemini",
        nargs = 0,
      },
    },
    {
      name = "GeminiToggle",
      callback = function()
        M.toggle_terminal()
      end,
      opts = { desc = "Toggle Gemini CLI terminal" },
    },
  }

  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd.name, cmd.callback, cmd.opts)
  end
end

--- Open Gemini CLI terminal
function M.open_terminal()
  -- This command should show the terminal window
  if M.state.terminal and M.state.terminal:is_valid() then
    -- Terminal exists, just show/focus it
    M.state.terminal:focus()
  else
    -- Create and show terminal
    M.state.terminal = terminal.open(M.state.config.terminal)
  end
end

--- Close Gemini CLI terminal
function M.close_terminal()
  if M.state.terminal then
    terminal.close(M.state.terminal)
    M.state.terminal = nil
  end
end

--- Toggle Gemini CLI terminal (open if closed, close if open and focused)
function M.toggle_terminal()
  if M.state.terminal and M.state.terminal:is_valid() then
    -- Terminal exists, check if it's currently focused
    local current_buf = vim.api.nvim_get_current_buf()
    
    -- Try to get terminal buffer ID (different providers may have different properties)
    local terminal_buf = nil
    if M.state.terminal.buf_id then
      terminal_buf = M.state.terminal.buf_id
    elseif M.state.terminal.buf then
      terminal_buf = M.state.terminal.buf
    end
    
    if terminal_buf and current_buf == terminal_buf then
      -- Terminal is focused, close it
      M.close_terminal()
    else
      -- Terminal exists but not focused, focus it
      M.state.terminal:focus()
    end
  else
    -- Terminal doesn't exist, create it
    M.open_terminal()
  end
end



--- Get relative path from current working directory
---@private
---@param absolute_path string
---@return string
function M._get_relative_path(absolute_path)
  local cwd = vim.fn.getcwd()

  -- If path starts with cwd, make it relative
  if absolute_path:sub(1, #cwd) == cwd then
    local relative = absolute_path:sub(#cwd + 2) -- +2 to skip the slash
    return relative ~= "" and relative or "."
  end

  -- Otherwise return the absolute path as-is
  return absolute_path
end

--- Ensure gemini terminal exists
---@private
function M._ensure_terminal()
  local logger = require("geminicli.logger")

  -- Check if terminal exists and is still valid
  if M.state.terminal and M.state.terminal.is_valid and M.state.terminal:is_valid() then
    logger.debug("Terminal is valid")
  else
    -- Terminal doesn't exist or is invalid, get or create one (without showing)
    logger.debug("Getting or creating terminal...")
    local snacks_terminal = require("geminicli.terminal.snacks")
    M.state.terminal = snacks_terminal.get_or_create(M.state.config.terminal)
  end
end

--- Send string to gemini terminal with trailing newline
---@private
---@param text string
function M._send_to_gemini(text)
  local logger = require("geminicli.logger")

  M._ensure_terminal()
  if not text or text == "" then
    logger.warn("Attempting to send empty text")
    vim.notify("Gemini: Nothing to send (empty text)", vim.log.levels.WARN)
    return
  end

  -- Ensure trailing newline for terminal input
  if not text:match("\n$") then
    text = text .. "\n"
  end

  logger.debug("Attempting to send to Gemini terminal: " .. vim.inspect(text))

  -- Check terminal state before sending
  if not M.state.terminal then
    logger.error("Terminal state is nil")
    vim.notify("Gemini: Terminal not initialized", vim.log.levels.ERROR)
    return
  end

  if not M.state.terminal.is_valid or not M.state.terminal:is_valid() then
    logger.warn("Terminal is not valid, recreating...")
    M._ensure_terminal()
  end

  logger.info("Sending text to Gemini terminal")
  terminal.send(M.state.terminal, text)
end

--- Command: GeminiSend - Send text/selection to Gemini
---@param opts table Command options
function M.send(opts)
  local selection = require("geminicli.selection")
  local integrations = require("geminicli.integrations")

  -- Priority 1: Explicit argument (file path or text)
  local args = opts and opts.args
  if args and args ~= "" then
    local expanded = vim.fn.expand(args)
    -- If it's a file path, use relative path
    if vim.fn.filereadable(expanded) == 1 then
      local relative_path = M._get_relative_path(expanded)
      M._send_to_gemini("@" .. relative_path)
    else
      M._send_to_gemini(expanded)
    end
    return
  end

  -- Priority 2: Check if we're in a file tree buffer
  if integrations.is_tree_buffer() then
    local files, error = integrations.get_selected_files_from_tree()

    if error then
      vim.notify("Gemini: " .. error, vim.log.levels.WARN)
      return
    end

    if files and #files > 0 then
      -- Send each file path to Gemini using relative paths
      for _, file_path in ipairs(files) do
        local relative_path = M._get_relative_path(file_path)
        M._send_to_gemini("@" .. relative_path)
      end

      -- Exit visual mode if we're in it
      vim.schedule(function()
        selection.exit_visual_mode()
      end)

      local logger = require("geminicli.logger")
      logger.info(string.format("Sent %d file(s) to Gemini", #files))
      return
    end
  end

  -- Priority 3: Visual selection (for non-tree buffers)
  local mode = vim.api.nvim_get_mode().mode
  local visual_selection = nil

  if mode == "v" or mode == "V" or mode == "\022" then
    -- Currently in visual mode
    visual_selection = selection.get_visual_selection()
  elseif opts and opts.line1 and opts.line2 then
    -- Range command (:'<,'>GeminiSend)
    visual_selection = selection.get_range_selection(opts.line1, opts.line2)
  end

  if visual_selection then
    local formatted = selection.format_for_gemini(visual_selection)
    local logger = require("geminicli.logger")
    logger.info("Sending visual selection to Gemini")
    M._send_to_gemini(formatted)

    -- Exit visual mode gracefully
    vim.schedule(function()
      selection.exit_visual_mode()
    end)
    return
  end

  -- Priority 4: Current line
  local current_line = vim.api.nvim_get_current_line()
  if current_line and current_line ~= "" then
    local logger = require("geminicli.logger")
    logger.info("Sending current line to Gemini")
    M._send_to_gemini(current_line)
    return
  end

  -- Priority 5: Current file path
  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path and buf_path ~= "" then
    local logger = require("geminicli.logger")
    logger.info("Sending current file path to Gemini")
    -- Send as file reference for Gemini to potentially analyze using relative path
    local relative_path = M._get_relative_path(vim.fn.expand(buf_path))
    M._send_to_gemini("@" .. relative_path)
    return
  end

  vim.notify("Nothing to send: no selection, no content, no file", vim.log.levels.WARN)
end


--- Command: GeminiAdd - Send current buffer path to Gemini
---@param opts table Command options
function M.add_file(opts)
  -- Get current buffer path
  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path and buf_path ~= "" then
    local logger = require("geminicli.logger")
    logger.info("Sending current file path to Gemini")
    -- Send as file reference for Gemini using relative path
    local relative_path = M._get_relative_path(vim.fn.expand(buf_path))
    M._send_to_gemini("@" .. relative_path)
    return
  end

  vim.notify("No file to add: current buffer has no file path", vim.log.levels.WARN)
end

return M
