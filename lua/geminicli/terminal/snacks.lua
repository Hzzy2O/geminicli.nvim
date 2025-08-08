---@brief [[
--- Snacks.nvim terminal provider
--- Uses snacks.nvim for enhanced terminal functionality
---@brief ]]

local M = {}

--- Snacks terminal wrapper
---@class SnacksTerminal
---@field terminal table Snacks terminal instance
local SnacksTerminal = {}
SnacksTerminal.__index = SnacksTerminal

--- Keep track of the single terminal instance
local terminal_instance = nil

--- Open a snacks terminal (show window)
---@param config table Terminal configuration
---@param gemini_cmd string Gemini startup command
---@return SnacksTerminal terminal
function M.open(config, gemini_cmd)
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    error("snacks.nvim is not installed")
  end

  -- Return existing instance if valid
  if terminal_instance and terminal_instance:is_valid() then
    terminal_instance:focus()
    return terminal_instance
  end

  local self = setmetatable({}, SnacksTerminal)

  -- Convert config to snacks format
  local win_opts = {
    position = config.split_side,
    width = config.split_width_percentage,
    height = config.split_height_percentage,
  }

  -- Build command
  local cmd = gemini_cmd or "gemini"
  if vim.fn.executable(cmd:match("^%S+")) == 0 then
    cmd = "bash -c 'echo \"Warning: gemini command not found. Please install Gemini CLI first.\"; exec bash'"
  end

  self.terminal = snacks.terminal.toggle(cmd, {
    win = win_opts,
    env = {
      EDITOR = "nvim",
    },
    cwd = vim.fn.getcwd(),
  })

  terminal_instance = self
  return self
end

--- Get or create terminal without showing window
---@param config table Terminal configuration
---@param gemini_cmd string Gemini startup command
---@return SnacksTerminal terminal
function M.get_or_create(config, gemini_cmd)
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    error("snacks.nvim is not installed")
  end

  -- Return existing instance if valid
  if terminal_instance and terminal_instance:is_valid() then
    return terminal_instance
  end

  local self = setmetatable({}, SnacksTerminal)

  -- Get existing terminal or create new one
  self.terminal = snacks.terminal.get("gemini")
  if not self.terminal then
    -- Create terminal but don't show it
    local win_opts = {
      position = config.split_side,
      width = config.split_width_percentage,
      height = config.split_height_percentage,
    }

    -- Create terminal with explicit command
    local cmd = gemini_cmd or "gemini"
    if vim.fn.executable(cmd:match("^%S+")) == 0 then
      cmd = "bash -c 'echo \"Warning: gemini command not found. Please install Gemini CLI first.\"; exec bash'"
    end

    self.terminal = snacks.terminal(cmd, {
      win = win_opts,
      env = {
        EDITOR = "nvim",
      },
      cwd = vim.fn.getcwd(),
    })

    -- Hide window immediately if it was shown
    if self.terminal and self.terminal.win and vim.api.nvim_win_is_valid(self.terminal.win) then
      vim.api.nvim_win_hide(self.terminal.win)
    end
  end

  terminal_instance = self
  return self
end

--- Close the terminal
function SnacksTerminal:close()
  if self.terminal then
    self.terminal:close()
  end
end

--- Focus the terminal window
function SnacksTerminal:focus()
  if self.terminal then
    if not self.terminal:win_valid() then
      self.terminal:show()
    end
    self.terminal:focus()
  end
end

--- Check if terminal is still valid
---@return boolean
function SnacksTerminal:is_valid()
  if not self.terminal then
    return false
  end

  -- Check if buffer is still valid
  if self.terminal.buf and vim.api.nvim_buf_is_valid(self.terminal.buf) then
    return true
  end

  return false
end

--- Send text to the terminal
---@param text string Text to send
function SnacksTerminal:send(text)
  local logger = require("geminicli.logger")

  if not self.terminal then
    logger.error("Terminal not initialized")
    vim.notify("Gemini: Terminal not initialized", vim.log.levels.ERROR)
    return
  end

  -- First ensure terminal is visible and focused
  if not self.terminal:win_valid() then
    logger.debug("Terminal window not valid, showing terminal")
    self.terminal:show()
  end

  -- Check if terminal has a send method
  if self.terminal.send then
    logger.debug("Using terminal.send method for text: " .. vim.inspect(text))
    local success, err = pcall(function()
      self.terminal:send(text)
    end)
    if not success then
      logger.error("Terminal send failed: " .. tostring(err))
      vim.notify("Gemini: Failed to send to terminal: " .. tostring(err), vim.log.levels.ERROR)
    else
      logger.info("Successfully sent text via terminal.send method")
    end
    return
  end

  -- Fallback: Get channel and send directly
  if not self.terminal.buf or not vim.api.nvim_buf_is_valid(self.terminal.buf) then
    logger.error("Terminal buffer invalid")
    vim.notify("Gemini: Terminal buffer invalid", vim.log.levels.ERROR)
    return
  end

  -- Get the channel ID
  local chan = nil

  -- Try different methods to get channel
  local ok_chan, buf_chan = pcall(vim.api.nvim_buf_get_option, self.terminal.buf, "channel")
  if ok_chan and buf_chan and buf_chan > 0 then
    chan = buf_chan
    logger.debug("Found channel via buf_get_option: " .. chan)
  elseif self.terminal.chan then
    chan = self.terminal.chan
    logger.debug("Found channel via terminal.chan: " .. chan)
  elseif self.terminal.job_id then
    chan = self.terminal.job_id
    logger.debug("Found channel via terminal.job_id: " .. chan)
  end

  if not chan or chan <= 0 then
    logger.error("No valid channel found for terminal")
    vim.notify("Gemini: No channel found for terminal", vim.log.levels.ERROR)
    return
  end

  -- Send text with proper error handling
  logger.debug("Sending to channel " .. chan .. ": " .. vim.inspect(text))
  local success, result = pcall(vim.fn.chansend, chan, text)
  if success and result > 0 then
    logger.info("Successfully sent " .. result .. " bytes via chansend")
  else
    logger.error("chansend failed: success=" .. tostring(success) .. ", result=" .. tostring(result))
    vim.notify("Gemini: Failed to send to terminal channel", vim.log.levels.ERROR)
  end
end

return M
