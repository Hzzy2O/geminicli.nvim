---@brief [[
--- Selection management for Gemini CLI
--- Handles visual selection extraction and formatting
---@brief ]]

local M = {}

--- Get current visual selection with proper handling
---@return table|nil selection Selection info or nil
function M.get_visual_selection()
  local mode = vim.api.nvim_get_mode().mode

  -- Check if we're in visual mode
  if not (mode == "v" or mode == "V" or mode == "\022") then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)

  if file_path == "" then
    file_path = "[No Name]"
  end

  -- Get visual selection marks
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  -- Ensure start comes before end
  if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
    start_pos, end_pos = end_pos, start_pos
  end

  -- Convert to 0-indexed for consistency
  local start_line = start_pos[2] - 1
  local end_line = end_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_col = end_pos[3]

  -- Handle line-wise visual mode
  if mode == "V" then
    start_col = 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, end_line, end_line + 1, false)
    if #lines > 0 then
      end_col = #lines[1]
    end
  end

  -- Handle block visual mode
  if mode == "\022" then
    -- Block mode needs special handling
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    local text_lines = {}
    for i, line in ipairs(lines) do
      local line_start = math.min(start_col + 1, #line + 1)
      local line_end = math.min(end_col, #line + 1)
      if line_start <= line_end then
        table.insert(text_lines, line:sub(line_start, line_end))
      else
        table.insert(text_lines, "")
      end
    end
    return {
      file_path = file_path,
      start_line = start_line,
      end_line = end_line,
      start_col = start_col,
      end_col = end_col,
      mode = "block",
      text = table.concat(text_lines, "\n"),
    }
  end

  -- Get the actual text
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  local text = ""

  if #lines == 0 then
    return nil
  elseif #lines == 1 then
    -- Single line selection
    text = lines[1]:sub(start_col + 1, end_col)
  else
    -- Multi-line selection
    local text_lines = {}
    text_lines[1] = lines[1]:sub(start_col + 1)
    for i = 2, #lines - 1 do
      text_lines[i] = lines[i]
    end
    text_lines[#lines] = lines[#lines]:sub(1, end_col)
    text = table.concat(text_lines, "\n")
  end

  return {
    file_path = file_path,
    start_line = start_line,
    end_line = end_line,
    start_col = start_col,
    end_col = end_col,
    mode = mode,
    text = text,
  }
end

--- Get selection from range (e.g., :'<,'>command)
---@param line1 number Starting line (1-indexed)
---@param line2 number Ending line (1-indexed)
---@return table|nil selection Selection info or nil
function M.get_range_selection(line1, line2)
  if not line1 or not line2 then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)

  if file_path == "" then
    file_path = "[No Name]"
  end

  -- Convert to 0-indexed
  local start_line = line1 - 1
  local end_line = line2 - 1

  -- Get the text
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  local text = table.concat(lines, "\n")

  return {
    file_path = file_path,
    start_line = start_line,
    end_line = end_line,
    start_col = 0,
    end_col = #(lines[#lines] or ""),
    mode = "line",
    text = text,
  }
end

--- Get relative path from current working directory
---@private
---@param absolute_path string
---@return string
local function get_relative_path(absolute_path)
  local cwd = vim.fn.getcwd()

  -- If path starts with cwd, make it relative
  if absolute_path:sub(1, #cwd) == cwd then
    local relative = absolute_path:sub(#cwd + 2) -- +2 to skip the slash
    return relative ~= "" and relative or "."
  end

  -- Otherwise return the absolute path as-is
  return absolute_path
end

--- Format selection for Gemini CLI input
---@param selection table Selection info
---@return string formatted Formatted text for Gemini
function M.format_for_gemini(selection)
  if not selection then
    return ""
  end

  local text = selection.text or ""

  -- For actual code/text selections from files, add context
  if selection.file_path and selection.file_path ~= "[No Name]" then
    -- Use relative path for cleaner display
    local display_path = get_relative_path(selection.file_path)
    -- Add file context with line numbers
    return string.format(
      "From %s (lines %d-%d):\n%s",
      display_path,
      selection.start_line + 1, -- Convert back to 1-indexed for display
      selection.end_line + 1,
      text
    )
  else
    -- Just return the text as-is
    return text
  end
end

--- Exit visual mode gracefully
function M.exit_visual_mode()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\022" then
    -- Feed escape key to exit visual mode
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "n", false)
  end
end

return M
