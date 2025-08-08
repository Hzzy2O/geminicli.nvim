# Gemini CLI Neovim Plugin

## Project Overview

This project is a Neovim plugin that integrates the Gemini CLI, allowing developers to interact with Google's Gemini models directly within the editor. It provides a terminal window for running the Gemini CLI and offers commands to send code snippets, selections, or entire files as context to the model.

The plugin is written in Lua and is designed to be configured and extended by the user.

### Key Features

*   Opens the Gemini CLI in a split terminal window within Neovim.
*   Sends the current visual selection, the current line, or the path of the current file to the Gemini CLI.
*   Integrates with file tree plugins (like Neo-tree or Nvim-tree) to send multiple selected files.
*   Configurable terminal position, size, and logging level.
*   Provides user commands for common actions (`:Gemini`, `:GeminiSend`, `:GeminiToggle`, etc.).

## Getting Started

### Installation

It is recommended to install this plugin using a plugin manager like `lazy.nvim`.

```lua
-- For lazy.nvim users:
{
  "your-username/geminicli.nvim", -- Replace with actual plugin path
  keys = {
    { "<leader>go", "<cmd>Gemini<cr>", desc = "🤖 Open Gemini" },
    { "<leader>gt", "<cmd>GeminiToggle<cr>", desc = "🤖 Toggle Gemini" },
    { "<leader>gq", "<cmd>GeminiClose<cr>", desc = "🤖 Close Gemini" },
    { "<leader>gp", "<cmd>GeminiSend<cr>", desc = "🤖 Send to Gemini", mode = { "n", "v" } },
    { "<leader>ga", "<cmd>GeminiAdd<cr>", desc = "🤖 Add file to Gemini" },
  },
  config = function()
    require("geminicli").setup()
  end,
}
```

### Configuration

The plugin can be configured using the `setup` function. The following options are available:

```lua
require("geminicli").setup({
  terminal = {
    provider = "auto", -- "auto", "native", or "snacks"
    split_side = "right", -- "right", "left", "bottom", "top"
    split_width_percentage = 0.30,
    split_height_percentage = 0.30,
  },
  log = {
    level = "info", -- "debug", "info", "warn", "error"
    file = vim.fn.stdpath("data") .. "/geminicli.log",
  },
})
```

## Usage

The primary way to interact with the plugin is through the provided user commands and keymaps.

### Commands

*   `:Gemini`: Opens the Gemini CLI terminal.
*   `:GeminiClose`: Closes the Gemini CLI terminal.
*   `:GeminiToggle`: Toggles the Gemini CLI terminal window.
*   `:GeminiSend`: Sends the current context to the Gemini CLI. This can be:
    *   A visual selection.
    *   The current line.
    *   The path to the current file.
    *   A file path provided as an argument.
*   `:GeminiAdd`: Sends the path of the current file to the Gemini CLI.

### Example Keymaps

```lua
-- Core terminal commands
vim.keymap.set("n", "<leader>go", "<cmd>Gemini<cr>", { desc = "🤖 Open Gemini" })
vim.keymap.set("n", "<leader>gt", "<cmd>GeminiToggle<cr>", { desc = "🤖 Toggle Gemini" })
vim.keymap.set("n", "<leader>gq", "<cmd>GeminiClose<cr>", { desc = "🤖 Close Gemini" })

-- Content sending commands
vim.keymap.set({ "n", "v" }, "<leader>gp", "<cmd>GeminiSend<cr>", { desc = "🤖 Send to Gemini" })
vim.keymap.set("n", "<leader>ga", "<cmd>GeminiAdd<cr>", { desc = "🤖 Add file to Gemini" })
```

## Development Conventions

### Code Style

The project uses `stylua` for code formatting. The configuration can be found in `.stylua.toml`.

*   **Column Width**: 120
*   **Indent Type**: Spaces (2)
*   **Quote Style**: Double quotes are preferred.

### Project Structure

*   `plugin/geminicli.lua`: The main entry point for the plugin, loaded by Neovim.
*   `lua/geminicli/init.lua`: The main module of the plugin, containing the core logic.
*   `lua/geminicli/config.lua`: Handles the default and user-provided configuration.
*   `lua/geminicli/terminal.lua`: Manages the terminal window.
*   `lua/geminicli/selection.lua`: Handles getting visual selections and other context.
*   `lua/geminicli/integrations.lua`: Provides integration with other plugins (e.g., file explorers).
*   `example-keymaps.lua`: Contains example keymaps for users.
