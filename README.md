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
  terminal_keymaps = {
    normal_mode = "<C-q>",         -- Keymap to exit terminal mode (default: <C-q>)
    window_nav = "<C-w>",          -- Keymap for window navigation (default: <C-w>)
    paste = "<C-S-v>",             -- Keymap for paste in terminal mode (default: <C-S-v>)
  },
  -- WSL2 optimization (enabled by default)
  wsl_optimization = {
    enabled = true,                -- Enable WSL2 optimizations
    check_clipboard = true,        -- Check clipboard configuration
    fix_paste = true,              -- Apply paste issue fixes
  },
  debug = false,                   -- Enable debug mode for verbose logging
})
```

## Usage / 使い方

Press `<leader>cm` (default) to toggle the CCManager terminal window.

`<leader>cm` (デフォルト) を押すことで、CCManagerのターミナルウィンドウを開閉できます。

### Key mappings in terminal mode / ターミナルモードでのキーマッピング

- `<C-q>` - Exit terminal mode to normal mode / ターミナルモードからノーマルモードへ
- `<C-w>` - Window navigation from terminal mode / ターミナルモードからのウィンドウ操作
- `<Esc>` - Passed through to CCManager for TUI operations / CCManagerのTUI操作に使用

### Commands / コマンド

- `:CCManagerDebug on/off` - Toggle debug mode / デバッグモードの切り替え
- `:CCManagerStatus` - Show terminal status / ターミナルの状態を表示
- `:CCManagerReset` - Reset terminal instance / ターミナルインスタンスをリセット
- `:CCManagerKill` - Force kill CCManager process / CCManagerプロセスを強制終了

## Error Handling and Debugging / エラーハンドリングとデバッグ

### Enhanced Error Handling / 強化されたエラーハンドリング

This plugin includes comprehensive error handling features:

このプラグインは包括的なエラーハンドリング機能を備えています：

- **Automatic retry**: Terminal creation with exponential backoff / **自動リトライ**: 指数バックオフによるターミナル作成
- **Process monitoring**: Detects abnormal process termination / **プロセス監視**: 異常なプロセス終了を検出
- **Detailed error messages**: Context-aware error reporting / **詳細なエラーメッセージ**: コンテキストを考慮したエラー報告
- **Safe API calls**: All Neovim API calls are wrapped for safety / **安全なAPI呼び出し**: 全てのNeovim API呼び出しを安全にラップ

### Debug Mode / デバッグモード

Enable debug mode to see detailed logs:

デバッグモードを有効にして詳細なログを確認できます：

```lua
-- In setup configuration
require("ccmanager").setup({
  debug = true,
})

-- Or using command
:CCManagerDebug on
```

## Troubleshooting / トラブルシューティング

### WSL2 Paste Issues / WSL2でのペースト問題

If you experience character loss when pasting in WSL2 environment, try the following solutions:

WSL2環境でペースト時に文字が欠落する場合は、以下の解決策を試してください：

#### 1. Optimize Clipboard Configuration / クリップボード設定の最適化

Add this to your Neovim configuration:

Neovimの設定に以下を追加してください：

```lua
-- WSL2 optimized clipboard configuration
vim.g.clipboard = {
  name = 'WslClipboard',
  copy = {
    ['+'] = 'clip.exe',
    ['*'] = 'clip.exe',
  },
  paste = {
    ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}
```

#### 2. Use Alternative Paste Methods / 代替のペースト方法を使用

- Use `Ctrl+Shift+V` (configured by default) / `Ctrl+Shift+V`を使用（デフォルトで設定済み）
- Exit to normal mode (`<C-q>`) and paste with `"+p` / 通常モードに戻って（`<C-q>`）`"+p`でペースト
- Right-click paste in your terminal / ターミナルで右クリックペースト

#### 3. Disable WSL2 Optimizations / WSL2最適化を無効化

If the optimizations cause issues, you can disable them:

最適化が問題を引き起こす場合は、無効化できます：

```lua
require("ccmanager").setup({
  wsl_optimization = {
    enabled = false,
  },
})
```

## Testing / テスト

### Running tests / テストの実行

This plugin uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing.

このプラグインは[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)を使用してテストを行っています。

#### Prerequisites / 前提条件

Install plenary.nvim if you haven't already:

plenary.nvimがインストールされていない場合はインストールしてください：

```lua
-- Using lazy.nvim
{ 'nvim-lua/plenary.nvim' }
```

#### Run all tests / 全てのテストを実行

```bash
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

#### Run specific test file / 特定のテストファイルを実行

```bash
nvim --headless -c "PlenaryBustedFile tests/ccmanager_spec.lua"
```

#### Run tests from within Neovim / Neovim内からテストを実行

```vim
:PlenaryBustedDirectory tests/
```

### Continuous Integration / 継続的インテグレーション

This project uses GitHub Actions for automated testing. Tests are run on:

このプロジェクトではGitHub Actionsを使用して自動テストを行っています。以下の条件でテストが実行されます：

- Push to `main` or `develop` branches / `main`または`develop`ブランチへのプッシュ時
- Pull requests to `main` branch / `main`ブランチへのプルリクエスト時
- Multiple Neovim versions (stable and nightly) / 複数のNeovimバージョン（安定版と開発版）

![Tests](https://github.com/ishiooon/ccmanager.nvim/workflows/Tests/badge.svg)

## Credits

- [kbwo/ccmanager](https://github.com/kbwo/ccmanager) - The amazing CCManager TUI application
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) - Terminal management plugin for Neovim
- [folke/lazy.nvim](https://github.com/folke/lazy.nvim) - Modern plugin manager for Neovim

## Author

ishiooon

## License

MIT
