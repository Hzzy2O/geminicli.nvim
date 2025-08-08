---@brief [[
--- Native Neovim terminal provider
--- Uses built-in terminal functionality
---@brief ]]

local M = {}

--- Terminal state
---@class NativeTerminal
---@field bufnr number Buffer number
---@field winid number Window ID
---@field job_id number Terminal job ID
local NativeTerminal = {}
NativeTerminal.__index = NativeTerminal

--- Open a native terminal
---@param config table Terminal configuration
---@param gemini_cmd string|table Gemini startup command (string or list)
---@return NativeTerminal terminal
function M.open(config, gemini_cmd)
  local self = setmetatable({}, NativeTerminal)

  -- Calculate split size
  local split_cmd
  if config.split_side == "right" then
    local width = math.floor(vim.o.columns * config.split_width_percentage)
    split_cmd = width .. "vsplit"
  elseif config.split_side == "left" then
    local width = math.floor(vim.o.columns * config.split_width_percentage)
    split_cmd = width .. "vsplit"
    vim.cmd("wincmd H")
  elseif config.split_side == "bottom" then
    local height = math.floor(vim.o.lines * config.split_height_percentage)
    split_cmd = height .. "split"
  elseif config.split_side == "top" then
    local height = math.floor(vim.o.lines * config.split_height_percentage)
    split_cmd = height .. "split"
    vim.cmd("wincmd K")
  end

  -- Create split
  vim.cmd(split_cmd)

  -- Create terminal buffer
  self.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(self.bufnr)

  -- Start terminal with Gemini CLI
  local cmd = gemini_cmd or "gemini"
  self.job_id = vim.fn.termopen(cmd, {
    on_exit = function(job_id, exit_code, event_type)
      -- Clean up when terminal exits
      if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
        vim.api.nvim_buf_delete(self.bufnr, { force = true })
      end
    end,
  })

  -- Store window ID
  self.winid = vim.api.nvim_get_current_win()

  -- Set buffer options
  vim.api.nvim_buf_set_option(self.bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(self.bufnr, "buflisted", false)

  -- Enter insert mode
  vim.cmd("startinsert")

  return self
end

--- Close the terminal
function NativeTerminal:close()
  if self.job_id then
    vim.fn.jobstop(self.job_id)
  end

  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, true)
  end

  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
end

--- Focus the terminal window
function NativeTerminal:focus()
  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_set_current_win(self.winid)
    vim.cmd("startinsert")
  end
end

--- Send text to the terminal
---@param text string Text to send
function NativeTerminal:send(text)
  if self.job_id then
    vim.fn.chansend(self.job_id, text)
  end
end

return M
