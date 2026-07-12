# grok-code.nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A lightweight Neovim integration for the `grok` CLI (Grok Build by xAI).

## What it does

This module provides convenient helpers for running the **official** Grok Build TUI inside Neovim terminal buffers. It follows the same interaction patterns as popular tools like `claude-code.nvim`, but stays faithful to the "just run the real CLI" philosophy:

- Open / toggle a persistent `grok` terminal (managed or raw).
- Support common CLI variants (`--continue`, `--resume`).
- Git-root aware working directory (optional).
- Send file references, ranges, and lines from your code buffers directly into the grok prompt using `@file` syntax (e.g. `@src/main.lua:10-42`).
- A picker (`:GrokSelect`) with common prompt templates (explain, fix, review, tests, etc.).
- Automatic buffer reload when Grok edits files.
- Friendly prompt if the `grok` binary is not installed yet.

It does **not** try to emulate or replace the Grok TUI — it simply launches the real binary (`grok`) in a Neovim `:terminal` (or via `termopen`) and adds a thin layer of ergonomics on top.

## Features

- `:GrokCode` / toggle (with configurable keys and variants)
- `:Grok` — plain/raw launcher that opens a vertical split on the right (same style you get from manually running `terminal grok`)
- Context helpers that append `@...` references (works with the managed toggle and the raw launcher)
- `:GrokSelect` — picker of ready-to-use actions/prompts
- Install guard that shows the official one-liner and docs link
- File watcher + `checktime` automation for edits made by the agent
- Per-git-root instance tracking (optional)

## Installation / Integration into Neovim

**Requirements:** Neovim ≥ 0.12 (developed and tested on 0.12.2).  
The plugin may work on older versions (0.10+), but these are not officially supported or tested.

This plugin is a simple Lua module. Install it with your preferred plugin manager or manually.

**Tested with:** vim.pack. 
Other managers are expected to work via standard mechanisms.

###  VimPlug

```vim
Plug 'paval-shlyk/grok-code.nvim'
```

After `plug#end()`:

```lua
require("grok-code").setup()
```

### lazy.nvim

```lua
{
  "paval-shlyk/grok-code.nvim",
  config = function()
    require("grok-code").setup()
  end,
}
```

### vim.pack (Neovim built-in)

```lua
vim.pack.add({
  "https://github.com/paval-shlyk/grok-code.nvim",
})

require("grok-code").setup()
```

### Manual / drop-in

Create `lua/grok-code/` in your Neovim configuration directory and place the `.lua` files from this repository there (so `require("grok-code")` can load the module). Then call setup.

Example:

```bash
mkdir -p ~/.config/nvim/lua/grok-code
# copy the *.lua files from the grok-code.nvim repo root into the directory above
```

## Configuration

All default values are shown below — override only the ones you want to change:

```lua
require("grok-code").setup({
  -- All values shown below are the defaults; override only what you need.
  window = {
    split_ratio = 0.35,
    position = 'botright vsplit',  -- 'botright split', 'float', etc.
    enter_insert = true,
    start_in_normal_mode = false,
    hide_numbers = true,
    hide_signcolumn = true,
    float = {  -- only relevant when position = 'float'
      width = '85%',
      height = '80%',
      row = 'center',
      col = 'center',
      relative = 'editor',
      border = 'rounded',
    },
  },
  refresh = {
    enable = true,
    updatetime = 100,
    timer_interval = 1200,
    show_notifications = true,
  },
  git = {
    use_git_root = true,
    multi_instance = true,
  },
  shell = {
    separator = '&&',
    pushd_cmd = 'pushd',
    popd_cmd = 'popd',
  },
  command = 'grok',  -- full path if not in $PATH
  command_variants = {
    continue = '--continue',
    resume = '--resume',
  },
  keymaps = {
    toggle = {
      normal = '<C-.>',
      terminal = '<C-.>',
      variants = {
        continue = '<leader>gC',
        resume = '<leader>gR',
      },
    },
    send_file_ref = '<leader>a',
    send_range_ref = '<leader>l',
    send_line_ref = '<leader>l',
    select = '<leader>s',
  },
  install = {
    url = 'https://x.ai/cli',
    command = 'curl -fsSL https://x.ai/cli/install.sh | bash',
    note = 'Grok Build is available to SuperGrok and X Premium Plus subscribers.',
  },
})
```

Keymaps may be set to `false` to disable any individual binding.

Optionally bind your own toggle key:

```lua
vim.keymap.set({ "n", "t" }, "<C-.>", function()
  require("grok-code").toggle()
end, { desc = "Toggle Grok Build" })
```

The module name stays `grok-code`, so `require("grok-code")` continues to work with any installation method.

## Usage

### Opening Grok

- `:GrokCode` (or your toggle key) — managed terminal with nice defaults (git root, vertical split on right, etc.).
- `:Grok` — raw launcher (exactly like manually doing a split + `terminal grok`).
- `:GrokCodeContinue` / `:GrokCodeResume` — variants.

Inside the terminal you interact with the real Grok TUI (all of Grok's own hotkeys work).

### Sending context from your code

- `<leader>a` (normal) — send `@current/file.lua`
- `<leader>l` (visual) — send `@current/file.lua:10-25`
- `<leader>l` (normal) — send `@current/file.lua:42` (current line)
- `:GrokSelect` — choose a canned prompt; the module appends the current file reference for you.

All of these append text to the grok terminal's input line (you can keep typing or press Enter).

You can also call them programmatically:

```lua
require("grok-code").send_file_ref()
require("grok-code").send_range_ref(10, 25)
require("grok-code").select()
```

### Raw usage

If you prefer to manage terminals yourself (like you do for Claude Code or opencode), you can ignore the managed toggle entirely and just use:

```vim
:Grok "explain the architecture"
```

or the plain command:

```vim
botright vsplit | terminal grok
```

The send helpers (`send_file_ref`, etc.) and `:GrokSend*` commands will still find any terminal buffer whose name contains "grok".

## Auto-session Integration

If you use `rmagatti/auto-session`, terminals are tricky because the underlying job cannot be restored.

A practical pattern (used in the originating config) is:

- Do **not** include `terminal` in `sessionoptions` (avoids "unknown buf_type=terminal" errors).
- In `pre_save_cmds`: close any grok-named terminal windows (keeps the session file clean).
- Persist a tiny per-cwd marker so you know whether a grok terminal was active:

```lua
-- (example — adapt paths/names as needed)
local function grok_session_marker()
  local dir = vim.fn.stdpath("data") .. "/grok"
  vim.fn.mkdir(dir, "p")
  local safe = vim.fn.getcwd():gsub("[^%w%-_%.]", "_")
  return dir .. "/had_grok_" .. safe
end

-- in pre_save_cmds
local had = false
-- ... scan windows for buftype == 'terminal' and name containing 'grok'
if had then
  vim.fn.writefile({ "1" }, grok_session_marker())
else
  pcall(vim.fn.delete, grok_session_marker())
end

-- also close the grok windows here
```

- In `post_restore_cmds` (or a `SessionLoadPost` autocmd):

```lua
vim.defer_fn(function()
  if vim.fn.filereadable(grok_session_marker()) == 1 then
    -- clean up any dead restored terminal buffer with "grok" in the name
    -- then
    require("grok-code").toggle_with_variant("continue")  -- or vim.cmd("Grok --continue")
  end
end, 150)
```

This gives you:
- Clean session files (no dead terminal state).
- The grok terminal + the *latest Grok conversation* for that directory only when you actually had it open.

See the originating `lua/config/setup.lua` for a full working example of the hooks.

## Known Limitations

- This is a thin wrapper. All the real power (and all the limitations) come from the `grok` binary itself.
- Terminal buffers have well-known session restoration limitations. The pattern above (marker + manual reopen with `--continue`) is the recommended workaround.
- To fully quit Neovim while a grok terminal is open, switch to a regular Neovim buffer/window and use `:qa` (or your preferred quit command). There is no special one-keystroke "quit everything from inside the grok TUI" provided by this module.

## References

- [opencode.nvim](https://github.com/NickvanDyke/opencode.nvim) — similar "send context to terminal agent" ideas.
- [claude-code.nvim](https://github.com/greggh/claude-code.nvim) (greggh) — the main inspiration for the toggle + variants + config shape.
- [claudecode.nvim](https://github.com/coder/claudecode.nvim) — another excellent Claude Code integration with deeper protocol support.
- [Grok Build](https://x.ai/cli) — the official CLI this module wraps.

## License

MIT License

Copyright (c) 2026 Paval Shlyk

See the [LICENSE](LICENSE) file for details.

---

This module was extracted from a personal Neovim configuration. Contributions and ideas for making the "raw CLI in terminal" experience even better are welcome!
