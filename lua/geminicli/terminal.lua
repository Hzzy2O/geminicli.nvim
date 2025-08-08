---@brief [[
--- Terminal management for Gemini CLI
--- Handles opening and managing terminal sessions
---@brief ]]

local M = {}

--- Open a terminal with Gemini CLI
---@param config table Terminal configuration
---@param gemini_cmd string Gemini startup command
---@return table terminal Terminal handle
function M.open(config, gemini_cmd)
  local provider = config.provider

  -- Auto-detect provider
  if provider == "auto" then
    if pcall(require, "snacks") then
      provider = "snacks"
    else
      provider = "native"
    end
  end

  local terminal_provider
  if provider == "snacks" then
    terminal_provider = require("geminicli.terminal.snacks")
  else
    terminal_provider = require("geminicli.terminal.native")
  end

  return terminal_provider.open(config, gemini_cmd)
end

--- Close a terminal
---@param terminal table Terminal handle
function M.close(terminal)
  if terminal and terminal.close then
    terminal:close()
  end
end

--- Focus a terminal
---@param terminal table Terminal handle
function M.focus(terminal)
  if terminal and terminal.focus then
    terminal:focus()
  end
end

--- Send text to terminal
---@param terminal table Terminal handle
---@param text string Text to send
function M.send(terminal, text)
  if terminal and terminal.send then
    terminal:send(text)
  end
end

return M
