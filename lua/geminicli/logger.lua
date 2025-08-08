---@brief [[
--- Logger module for geminicli.nvim
--- Provides structured logging with different levels
---@brief ]]

local M = {}

--- Log levels
---@type table<string, number>
M.levels = {
  debug = 0,
  info = 1,
  warn = 2,
  error = 3,
}

--- Current configuration
---@type table
local config = {
  level = "info",
  file = nil,
}

--- Current log level as number
---@type number
local current_level = M.levels.info

--- Setup logger with configuration
---@param opts table? Logger configuration
function M.setup(opts)
  if opts then
    config.level = opts.level or config.level
    config.file = opts.file or config.file
    current_level = M.levels[config.level] or M.levels.info
  end
end

--- Write log message to file
---@param level string Log level
---@param message string Log message
local function write_to_file(level, message)
  if not config.file then
    return
  end

  local file = io.open(config.file, "a")
  if file then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    file:write(string.format("[%s] [%s] %s\n", timestamp, level:upper(), message))
    file:close()
  end
end

--- Format message from multiple arguments
---@param ... any Arguments to format
---@return string Formatted message
local function format_message(...)
  local args = { ... }
  local parts = {}

  for i, arg in ipairs(args) do
    if type(arg) == "table" then
      parts[i] = vim.inspect(arg)
    else
      parts[i] = tostring(arg)
    end
  end

  return table.concat(parts, " ")
end

--- Log debug message
---@param ... any Message parts
function M.debug(...)
  if current_level > M.levels.debug then
    return
  end

  local message = format_message(...)
  write_to_file("debug", message)

  if vim.fn.has("nvim-0.8") == 1 then
    vim.notify(message, vim.log.levels.DEBUG, { title = "geminicli.nvim" })
  end
end

--- Log info message
---@param ... any Message parts
function M.info(...)
  if current_level > M.levels.info then
    return
  end

  local message = format_message(...)
  write_to_file("info", message)

  if vim.fn.has("nvim-0.8") == 1 then
    vim.notify(message, vim.log.levels.INFO, { title = "geminicli.nvim" })
  end
end

--- Log warning message
---@param ... any Message parts
function M.warn(...)
  if current_level > M.levels.warn then
    return
  end

  local message = format_message(...)
  write_to_file("warn", message)
  vim.notify(message, vim.log.levels.WARN, { title = "geminicli.nvim" })
end

--- Log error message
---@param ... any Message parts
function M.error(...)
  if current_level > M.levels.error then
    return
  end

  local message = format_message(...)
  write_to_file("error", message)
  vim.notify(message, vim.log.levels.ERROR, { title = "geminicli.nvim" })
end

--- Set log level
---@param level string New log level
function M.set_level(level)
  if M.levels[level] then
    config.level = level
    current_level = M.levels[level]
  else
    M.warn("Invalid log level:", level)
  end
end

--- Get current log level
---@return string Current log level
function M.get_level()
  return config.level
end

return M
