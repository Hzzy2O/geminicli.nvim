# geminicli.nvim

Integrate Gemini CLI with Neovim without modifying the CLI itself. Provides a smoother workflow and built-in commands.

> Recommended: use `nvr` (neovim-remote) so external `nvim` calls are routed into your current Neovim session.

## Features
- Commands: `:Gemini`, `:GeminiToggle`, `:GeminiQuit`, `:GeminiSend`, `:GeminiAdd`
- Keymaps to send selection/current buffer content to Gemini CLI
- Optional: with `nvr` and a small wrapper, forward CLI-launched `nvim` to the existing Neovim instance

## Requirements
- Neovim 0.8+
- Installed Gemini CLI
- Optional: `nvr` (recommended)
  - `pipx install neovim-remote` or `pip install --user neovim-remote`

## Install
Example with Lazy.nvim:

```lua
{
  "duoduohe/geminicli.nvim",
  -- event = "VeryLazy", -- optional
  opts = {
    -- Terminal options
    terminal = {
      provider = "auto",      -- "auto" | "native" | "snacks"
      split_side = "right",    -- "right" | "left" | "bottom" | "top"
      split_width_percentage = 0.30,
      split_height_percentage = 0.30,
      -- Startup command
      -- terminal_cmd = "gemini --yolo",
    },

    -- Logging
    -- log = { level = "info", file = vim.fn.stdpath("data") .. "/geminicli.log" },
  },
  keys = {
    { "<leader>g",  nil,                 desc = "Gemini" },
    { "<leader>go", "<cmd>Gemini<cr>",        desc = "Enable Gemini" },
    { "<leader>gt", "<cmd>GeminiToggle<cr>", desc = "Toggle Gemini" },
    { "<leader>gq", "<cmd>GeminiQuit<cr>",   desc = "Quit Gemini" },
    { "<leader>gp", "<cmd>GeminiSend<cr>",   desc = "Add to Gemini", mode = { "n", "v" } },
    { "<leader>ga", "<cmd>GeminiAdd<cr>",    desc = "Add current to Gemini" },
  },
}
```

You can also use your preferred plugin manager; just replicate the `keys` mapping above.

See `example-keymaps.lua` in the repo for a full example.

## Configuration
- **terminal.terminal_cmd**: startup command for the embedded terminal. Accepts a string, e.g. `"gemini --yolo"`.

Defaults to `"gemini"`.

## Commands
- `:Gemini`: start or connect to a Gemini session
- `:GeminiToggle`: toggle enabled/disabled state
- `:GeminiQuit`: close Gemini session/panel
- `:GeminiSend`: send visual selection or current buffer to Gemini
- `:GeminiAdd`: add current file (or current buffer) to Gemini context

## Optional: nvr forwarding
If you want the `nvim` spawned by Gemini CLI to open inside your current Neovim window:
1. Ensure Neovim starts an RPC server and writes its address to a stable file (e.g. `~/.cache/geminicli.nvim/server`).
2. Put a lightweight `nvim` wrapper earlier in `PATH` that reads the address and calls `nvr --servername`; fall back to the real `nvim` if unavailable.

> This step is optional but significantly improves collaboration with the Gemini CLI.

## Troubleshooting
- Ensure Gemini CLI works in your shell
- If using `nvr`, verify `pipx run nvr --version` or `nvr --version`
- If enabling the wrapper, ensure the real `nvim` path and `PATH` ordering are correct to avoid recursion

## License
MIT
