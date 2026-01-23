# nodejumper.nvim

A flash.nvim-like Neovim plugin for jumping to treesitter nodes. Press a key, see labels appear on all visible treesitter nodes, type the label to jump to that location.

## Features

- Jump to any visible treesitter node with minimal keystrokes
- Labels use home row keys for quick access
- Works in normal, visual, and operator-pending modes
- Configurable labels, keymaps, and appearance

## Requirements

- Neovim >= 0.8.0
- Treesitter parser for your language (`:TSInstall <language>`)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "burneikis/nodejumper.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "S", mode = { "n", "x", "o" }, function() require("nodejumper").jump() end, desc = "Jump to treesitter node" },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "burneikis/nodejumper.nvim",
  config = function()
    require("nodejumper").setup()
    vim.keymap.set({ "n", "x", "o" }, "S", function() require("nodejumper").jump() end, { desc = "Jump to treesitter node" })
  end
}
```

## Usage

1. Press your configured key (e.g., `S`) in normal, visual, or operator-pending mode
2. Labels appear on all visible treesitter nodes
3. Type the label character(s) to jump to that node
4. Press `<Esc>` to cancel

### Commands

- `:NodejumperJump` - Start a jump session
- `:NodejumperCancel` - Cancel active jump session

## Configuration

### Configuration

Pass options via the `opts` table in your lazy.nvim spec:

```lua
{
  "burneikis/nodejumper.nvim",
  event = "VeryLazy",
  opts = {
    -- Labels used for jumping (home row keys first)
    labels = "asdfghjklqwertyuiopzxcvbnm",

    -- Minimum node size to show labels (reduces clutter)
    min_node_size = 3,

    -- Minimum spacing between labels on same line
    min_spacing = 2,

    -- Dim background text during jump mode
    dim_background = true,

    -- Include all nodes (even tiny ones) - expert mode
    all_nodes = false,

    -- Advanced options (rarely need to change)
    advanced = {
      cancel_key = "<Esc>",
      min_word_length = 0,
      priority = 1000,
      highlight = {
        label = "NodejumperLabel",
        dim = "NodejumperDim",
      },
    },
  },
  keys = {
    { "S", mode = { "n", "x", "o" }, function() require("nodejumper").jump() end, desc = "Jump to treesitter node" },
  },
}
```

## Highlight Groups

You can customize the appearance by setting these highlight groups:

```lua
-- Labels (default: white on pink, bold)
vim.api.nvim_set_hl(0, "NodejumperLabel", { fg = "#ffffff", bg = "#ff007c", bold = true })

-- Dimmed text (default: gray)
vim.api.nvim_set_hl(0, "NodejumperDim", { fg = "#545c7e" })
```

## API

```lua
local nodejumper = require('nodejumper')

-- Start a jump session
nodejumper.jump()

-- Cancel active jump session
nodejumper.cancel()

-- Check if jump session is active
nodejumper.is_active()
```

## License

MIT
