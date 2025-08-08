---@brief [[
--- Configuration management for geminicli.nvim
--- Handles default configuration and merging with user options
---@brief ]]

local M = {}

--- Default configuration
---@type table
M.defaults = {
  -- Terminal settings
  terminal = {
    -- Terminal provider: "auto", "native", "snacks"
    provider = "auto",
    -- Terminal position: "right", "left", "bottom", "top"
    split_side = "right",
    -- Terminal width percentage (for vertical splits)
    split_width_percentage = 0.30,
    -- Terminal height percentage (for horizontal splits)
    split_height_percentage = 0.30,
    -- Startup command for Gemini CLI. String or list.
    -- Examples: "gemini", "gemini --yolo", { "gemini", "--yolo" }
    terminal_cmd = "gemini",
  },

  -- Logging settings
  log = {
    -- Log level: "debug", "info", "warn", "error"
    level = "info",
    -- Log file path
    file = vim.fn.stdpath("data") .. "/geminicli.log",
  },
}

--- Deep merge two tables
---@param base table Base configuration
---@param override table Override configuration
---@return table Merged configuration
local function deep_merge(base, override)
  local result = vim.tbl_deep_extend("force", {}, base)

  for key, value in pairs(override) do
    if type(value) == "table" and type(result[key]) == "table" then
      result[key] = deep_merge(result[key], value)
    else
      result[key] = value
    end
  end

  return result
end

--- Validate configuration
---@param config table Configuration to validate
---@return boolean is_valid
---@return string? error_message
local function validate_config(config)
  -- Validate terminal provider
  local valid_providers = { "auto", "native", "snacks" }
  if not vim.tbl_contains(valid_providers, config.terminal.provider) then
    return false, "Invalid terminal provider: " .. config.terminal.provider
  end

  -- Validate terminal position
  local valid_positions = { "right", "left", "bottom", "top" }
  if not vim.tbl_contains(valid_positions, config.terminal.split_side) then
    return false, "Invalid terminal position: " .. config.terminal.split_side
  end

  -- Validate percentages
  if config.terminal.split_width_percentage <= 0 or config.terminal.split_width_percentage >= 1 then
    return false, "split_width_percentage must be between 0 and 1"
  end
  if config.terminal.split_height_percentage <= 0 or config.terminal.split_height_percentage >= 1 then
    return false, "split_height_percentage must be between 0 and 1"
  end

  -- Validate log level
  local valid_levels = { "debug", "info", "warn", "error" }
  if not vim.tbl_contains(valid_levels, config.log.level) then
    return false, "Invalid log level: " .. config.log.level
  end

  -- Validate terminal_cmd: allow string (non-empty) or list of strings (non-empty)
  local cmd = config.terminal and config.terminal.terminal_cmd
  if type(cmd) == "string" then
    if cmd == "" then
      return false, "terminal.terminal_cmd string must not be empty"
    end
  elseif type(cmd) == "table" then
    if #cmd == 0 then
      return false, "terminal.terminal_cmd list must not be empty"
    end
    for i, v in ipairs(cmd) do
      if type(v) ~= "string" or v == "" then
        return false, string.format("terminal.terminal_cmd[%d] must be a non-empty string", i)
      end
    end
  else
    return false, "terminal.terminal_cmd must be a string or a list of strings"
  end

  return true
end

--- Merge user configuration with defaults
---@param opts table? User configuration
---@return table Merged configuration
function M.merge(opts)
  local config = deep_merge(M.defaults, opts or {})

  -- Validate merged configuration
  local is_valid, error_msg = validate_config(config)
  if not is_valid then
    vim.notify("geminicli.nvim: Invalid configuration: " .. error_msg, vim.log.levels.ERROR)
    -- Return defaults on validation error
    return M.defaults
  end

  return config
end

return M
