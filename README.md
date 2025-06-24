# ccmanager.nvim

※This project is under construction.
※このプロジェクトは作成中です。

Neovim plugin for [CCManager](https://github.com/kbwo/ccmanager) - Claude Code Session Manager integration using toggleterm.nvim.

CCManager is a TUI application for managing multiple Claude Code sessions across Git worktrees. This plugin allows you to run CCManager directly within Neovim.

[CCManager](https://github.com/kbwo/ccmanager)は、複数のClaude Codeセッションを Git worktree間で管理するためのTUIアプリケーションです。このプラグインを使用することで、NeovimからCCManagerを直接起動できます。

## Requirements

- Neovim >= 0.11.0
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- Node.js (for running `npx ccmanager`)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ishiooon/ccmanager.nvim",
  dependencies = {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true
  },
  config = function()
    require("ccmanager").setup({
      -- your configuration
    })
  end,
}
```

## Configuration

Default configuration:

```lua
require("ccmanager").setup({
  keymap = "<leader>cm",           -- Keymap to toggle CCManager
  window = {
    size = 0.3,                    -- Window size (0-1 for percentage)
    position = "right",            -- Window position: "right", "left", "bottom", "top"
  },
  command = "npx ccmanager",       -- Command to run CCManager
})
```

## Usage / 使い方

Press `<leader>cm` (default) to toggle the CCManager terminal window.

`<leader>cm` (デフォルト) を押すことで、CCManagerのターミナルウィンドウを開閉できます。

### Key mappings in terminal mode / ターミナルモードでのキーマッピング

- `<Esc>` - Exit terminal mode to normal mode / ターミナルモードからノーマルモードへ
- `<C-w>` - Window navigation from terminal mode / ターミナルモードからのウィンドウ操作

## Testing / テスト

This plugin uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing.

このプラグインは[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)を使用してテストを実行します。

### Running tests locally / ローカルでのテスト実行

1. Install plenary.nvim / plenary.nvimをインストール:
   ```bash
   git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
   ```

2. Run all tests / 全てのテストを実行:
   ```bash
   nvim --headless -c "PlenaryBustedDirectory spec/ { minimal_init = 'spec/spec_helper.lua' }"
   ```

3. Run specific test file / 特定のテストファイルを実行:
   ```bash
   nvim --headless -c "PlenaryBustedFile spec/ccmanager/init_spec.lua"
   ```

### CI/CD

Tests are automatically run on GitHub Actions for:
- Push to `main` and `develop` branches
- Pull requests to `main` branch
- Both stable and nightly versions of Neovim

GitHubActionsで以下の条件で自動的にテストが実行されます：
- `main`と`develop`ブランチへのプッシュ
- `main`ブランチへのプルリクエスト
- Neovimのstableとnightlyバージョンでテスト

## Credits

- [kbwo/ccmanager](https://github.com/kbwo/ccmanager) - The amazing CCManager TUI application
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) - Terminal management plugin for Neovim
- [folke/lazy.nvim](https://github.com/folke/lazy.nvim) - Modern plugin manager for Neovim
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Useful lua functions used in lots of plugins

## Author

ishiooon

## License

MIT
