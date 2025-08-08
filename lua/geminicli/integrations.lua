---@brief [[
--- File tree integration for Gemini CLI
--- Handles getting selected files from various file explorers
---@brief ]]

local M = {}

--- Get selected files from the current tree explorer
---@return table|nil files List of file paths, or nil if error
---@return string|nil error Error message if operation failed
function M.get_selected_files_from_tree()
  local current_ft = vim.bo.filetype

  if current_ft == "NvimTree" then
    return M._get_nvim_tree_selection()
  elseif current_ft == "neo-tree" then
    return M._get_neotree_selection()
  elseif current_ft == "oil" then
    return M._get_oil_selection()
  elseif current_ft == "minifiles" then
    return M._get_mini_files_selection()
  else
    return nil, "Not in a supported tree buffer (current filetype: " .. current_ft .. ")"
  end
end

--- Get selected files from nvim-tree
---@return table files List of file paths
---@return string|nil error Error message if operation failed
function M._get_nvim_tree_selection()
  local success, nvim_tree_api = pcall(require, "nvim-tree.api")
  if not success then
    return {}, "nvim-tree not available"
  end

  local files = {}

  -- Check for marked files first
  local marks = nvim_tree_api.marks.list()
  if marks and #marks > 0 then
    for _, mark in ipairs(marks) do
      if mark.type == "file" and mark.absolute_path and mark.absolute_path ~= "" then
        table.insert(files, mark.absolute_path)
      elseif mark.type == "directory" and mark.absolute_path and mark.absolute_path ~= "" then
        table.insert(files, mark.absolute_path)
      end
    end

    if #files > 0 then
      return files, nil
    end
  end

  -- Fall back to node under cursor
  local node = nvim_tree_api.tree.get_node_under_cursor()
  if node then
    if node.absolute_path and node.absolute_path ~= "" then
      return { node.absolute_path }, nil
    end
  end

  return {}, "No file found under cursor"
end

--- Get selected files from neo-tree
---@return table files List of file paths
---@return string|nil error Error message if operation failed
function M._get_neotree_selection()
  local success, manager = pcall(require, "neo-tree.sources.manager")
  if not success then
    return {}, "neo-tree not available"
  end

  local state = manager.get_state("filesystem")
  if not state then
    return {}, "neo-tree filesystem state not available"
  end

  local files = {}

  -- Check visual mode selection
  local mode = vim.fn.mode()
  if mode == "V" or mode == "v" or mode == "\22" then
    local current_win = vim.api.nvim_get_current_win()

    if state.winid and state.winid == current_win then
      local start_pos = vim.fn.getpos("'<")[2]
      local end_pos = vim.fn.getpos("'>")[2]

      -- Fallback to cursor position if marks are not valid
      if start_pos == 0 or end_pos == 0 then
        local cursor_pos = vim.api.nvim_win_get_cursor(0)[1]
        start_pos = cursor_pos
        end_pos = cursor_pos
      end

      if end_pos < start_pos then
        start_pos, end_pos = end_pos, start_pos
      end

      for line = start_pos, end_pos do
        local node = state.tree:get_node(line)
        if node and node.path and node.path ~= "" then
          table.insert(files, node.path)
        end
      end

      if #files > 0 then
        return files, nil
      end
    end
  end

  -- Check for regular selection
  if state.tree then
    local selection = nil

    if state.tree.get_selection then
      selection = state.tree:get_selection()
    end

    if (not selection or #selection == 0) and state.selected_nodes then
      selection = state.selected_nodes
    end

    if selection and #selection > 0 then
      for _, node in ipairs(selection) do
        if node.path and node.path ~= "" then
          table.insert(files, node.path)
        end
      end

      if #files > 0 then
        return files, nil
      end
    end
  end

  -- Fall back to node under cursor
  if state.tree then
    local node = state.tree:get_node()
    if node and node.path and node.path ~= "" then
      return { node.path }, nil
    end
  end

  return {}, "No file found under cursor"
end

--- Get selected files from oil.nvim
---@return table files List of file paths
---@return string|nil error Error message if operation failed
function M._get_oil_selection()
  local success, oil = pcall(require, "oil")
  if not success then
    return {}, "oil.nvim not available"
  end

  local files = {}

  -- Get current directory from oil
  local current_dir = oil.get_current_dir()
  if not current_dir then
    return {}, "Could not get current directory from oil"
  end

  -- Check visual mode
  local mode = vim.fn.mode()
  if mode == "V" or mode == "v" then
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    for line = start_line, end_line do
      local entry = oil.get_entry_on_line(0, line)
      if entry and entry.name then
        local full_path = current_dir .. entry.name
        if entry.type == "directory" then
          full_path = full_path .. "/"
        end
        table.insert(files, full_path)
      end
    end

    if #files > 0 then
      return files, nil
    end
  end

  -- Fall back to cursor position
  local entry = oil.get_cursor_entry()
  if entry and entry.name then
    local full_path = current_dir .. entry.name
    if entry.type == "directory" then
      full_path = full_path .. "/"
    end
    return { full_path }, nil
  end

  return {}, "No file found under cursor"
end

--- Get selected files from mini.files
---@return table files List of file paths
---@return string|nil error Error message if operation failed
function M._get_mini_files_selection()
  local success, mini_files = pcall(require, "mini.files")
  if not success then
    return {}, "mini.files not available"
  end

  local files = {}

  -- Get current entry
  local current_entry = mini_files.get_fs_entry()
  if current_entry and current_entry.path then
    table.insert(files, current_entry.path)
    return files, nil
  end

  return {}, "No file found under cursor"
end

--- Check if current buffer is a file tree
---@return boolean
function M.is_tree_buffer()
  local ft = vim.bo.filetype
  return ft == "NvimTree" or ft == "neo-tree" or ft == "oil" or ft == "minifiles"
end

return M
