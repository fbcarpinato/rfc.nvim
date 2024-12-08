# rfc.nvim

A neovim plugin that allows to query [RFCs](https://en.wikipedia.org/wiki/Request_for_Comments) and open them in a new buffer.

## Installation

You can use you favorite package manager.

Using lazy.nvim

```lua
return {
  {
    dir = "fbcarpinato/rfc.nvim",
    name = "rfc",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("rfc").setup({})
    end,
  },
}
```

## Usage

Example

```vim
:RFC
```
