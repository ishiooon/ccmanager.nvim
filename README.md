# ccmanager.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.11.0+-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=white)](https://neovim.io)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Tests](https://github.com/ishiooon/ccmanager.nvim/workflows/Tests/badge.svg)](https://github.com/ishiooon/ccmanager.nvim/actions)

Neovim plugin for [CCManager](https://github.com/kbwo/ccmanager) - Claude Code Session Manager integration using toggleterm.nvim.

[日本語](#日本語) | [English](#english)

## English

CCManager is a TUI application for managing multiple Claude Code sessions across Git worktrees. This plugin provides seamless integration with Neovim, allowing you to manage your AI coding sessions without leaving your editor.

### ✨ Features

- 🚀 **Quick Access**: Toggle CCManager with a single keymap
- 🎯 **Flexible Window Positioning**: Support for split and floating windows
- 🔧 **Highly Configurable**: Customize keymaps, window size, and behavior
- 🌍 **WSL2 Optimized**: Special optimizations for Windows Subsystem for Linux
- 📦 **Zero Configuration**: Works out of the box with sensible defaults

## 日本語

[CCManager](https://github.com/kbwo/ccmanager)は、複数のClaude Codeセッションを Git worktree間で管理するためのTUIアプリケーションです。このプラグインを使用することで、エディタを離れることなくAIコーディングセッションを管理できます。

### ✨ 機能

- 🚀 **クイックアクセス**: 単一のキーマップでCCManagerを切り替え
- 🎯 **柔軟なウィンドウ配置**: 分割ウィンドウとフローティングウィンドウをサポート
- 🔧 **高度なカスタマイズ性**: キーマップ、ウィンドウサイズ、動作をカスタマイズ可能
- 🌍 **WSL2最適化**: Windows Subsystem for Linux向けの特別な最適化
- 📦 **ゼロ設定**: 適切なデフォルト値ですぐに動作

## 📋 Requirements / 必要要件

### Prerequisites / 前提条件

- **Neovim** >= 0.11.0
- **Node.js** >= 16.0.0 (for running CCManager)
- **Git** (for managing worktrees)
- **[toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)** (plugin dependency)

### Installing CCManager / CCManagerのインストール

First, install CCManager globally using npm:
まず、npmを使用してCCManagerをグローバルにインストールします：

```bash
npm install -g ccmanager
```

Or use it directly with npx (no installation required):
または、npxで直接使用します（インストール不要）：

```bash
npx ccmanager
```

## 🚀 Installation / インストール

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

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
  keys = {
    { "<leader>cm", desc = "Toggle CCManager" },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'ishiooon/ccmanager.nvim',
  requires = {
    {'akinsho/toggleterm.nvim', tag = '*', config = function()
      require("toggleterm").setup()
    end}
  },
  config = function()
    require("ccmanager").setup({
      -- your configuration
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'akinsho/toggleterm.nvim', { 'tag': '*' }
Plug 'ishiooon/ccmanager.nvim'

" After installation, add to your init.vim:
lua << EOF
require("toggleterm").setup()
require("ccmanager").setup({
  -- your configuration
})
EOF
```

### Using native package management

```bash
# Install in pack/*/start for automatic loading
git clone https://github.com/akinsho/toggleterm.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/toggleterm.nvim
git clone https://github.com/ishiooon/ccmanager.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/ccmanager.nvim
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
})
```

### 🎨 Advanced Configuration Examples / 高度な設定例

#### Floating Window / フローティングウィンドウ

```lua
require("ccmanager").setup({
  window = {
    position = "float",
    size = 0.8,  -- 80% of screen
  },
})
```

#### Custom Command with Arguments / カスタムコマンドと引数

```lua
require("ccmanager").setup({
  -- Use global installation
  command = "ccmanager --config ~/.config/ccmanager/config.json",
  
  -- Or use specific node version
  -- command = "~/.nvm/versions/node/v18.0.0/bin/node $(which ccmanager)",
})
```

#### Disable Auto-keymap / 自動キーマップを無効化

```lua
require("ccmanager").setup({
  keymap = nil,  -- Disable automatic keymap
})

-- Set up custom keymaps manually
vim.keymap.set("n", "<leader>cc", function()
  require("ccmanager.terminal").toggle()
end, { desc = "Toggle CCManager" })

-- Additional custom commands
vim.keymap.set("n", "<leader>cr", function()
  -- Reset terminal before opening
  local terminal = require("ccmanager.terminal")
  terminal.reset()
  terminal.toggle()
end, { desc = "Reset and open CCManager" })
```

#### Different Window Positions / 異なるウィンドウ位置

```lua
-- Bottom split (like traditional terminal)
require("ccmanager").setup({
  window = {
    position = "bottom",
    size = 0.3,  -- 30% height
  },
})

-- Left sidebar
require("ccmanager").setup({
  window = {
    position = "left",
    size = 0.25,  -- 25% width
  },
})

-- Top split
require("ccmanager").setup({
  window = {
    position = "top",
    size = 0.2,  -- 20% height
  },
})
```

## 📖 Usage / 使い方

Press `<leader>cm` (default) to toggle the CCManager terminal window.

`<leader>cm` (デフォルト) を押すことで、CCManagerのターミナルウィンドウを開閉できます。

### Key mappings in terminal mode / ターミナルモードでのキーマッピング

- `<C-q>` - Exit terminal mode to normal mode / ターミナルモードからノーマルモードへ
- `<C-w>` - Window navigation from terminal mode / ターミナルモードからのウィンドウ操作
- `<Esc>` - Passed through to CCManager for TUI operations / CCManagerのTUI操作に使用

### Commands / コマンド

- `:CCManagerShowConfig` - Display current configuration / 現在の設定を表示
- `:CCManagerValidateConfig` - Validate current configuration / 現在の設定を検証
## 🔧 Troubleshooting / トラブルシューティング

### Common Issues / よくある問題

#### CCManager won't start / CCManagerが起動しない

1. **Check Node.js installation / Node.jsのインストールを確認**
   ```bash
   node --version  # Should be >= 16.0.0
   npm --version
   ```

2. **Verify CCManager installation / CCManagerのインストールを確認**
   ```bash
   which ccmanager
   # or / または
   npx ccmanager --version
   ```

3. **Check error messages / エラーメッセージを確認**
   ```vim
   :messages
   ```

#### Terminal window size issues / ターミナルウィンドウサイズの問題

If the terminal window is too small or too large:
ターミナルウィンドウが小さすぎる、または大きすぎる場合：
```lua
require("ccmanager").setup({
  window = {
    size = function()
      -- Custom size calculation
      if vim.o.columns > 200 then
        return 0.3  -- 30% for wide screens
      else
        return 0.5  -- 50% for narrow screens
      end
    end,
  },
})
```

### Configuration Validation / 設定のバリデーション

CCManager automatically validates your configuration to prevent errors:

CCManagerは設定を自動的に検証してエラーを防ぎます：

#### Validated Settings / 検証される設定

- **window.size**: Must be a number between 0 and 1 / 0から1の間の数値である必要があります
- **window.position**: Must be one of: `right`, `left`, `float`, `bottom`, `top`, `vertical`, `horizontal`
- **command**: Must be a non-empty string / 空でない文字列である必要があります
- **keymap**: Must be a valid keymap string / 有効なキーマップ文字列である必要があります
- **terminal_keymaps**: Must be a table with string values / 文字列値を持つテーブルである必要があります
- **wsl_optimization**: Must contain boolean values / ブール値を含む必要があります

#### Example / 例

```lua
require("ccmanager").setup({
  window = {
    size = 2.0,  -- Invalid: will be set to 0.3 (default)
    position = "center",  -- Invalid: will be set to "right" (default)
  },
  command = "",  -- Invalid: will be set to "npx ccmanager" (default)
})
```

Invalid settings will be replaced with defaults and you'll see a warning message.

無効な設定はデフォルト値に置き換えられ、警告メッセージが表示されます.

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

## ❓ FAQ / よくある質問

### Q: Can I use ccmanager.nvim with other terminal plugins? / 他のターミナルプラグインと併用できますか？

A: Yes, ccmanager.nvim uses toggleterm.nvim which coexists well with other plugins. Each terminal instance is isolated.

はい、ccmanager.nvimはtoggleterm.nvimを使用しており、他のプラグインとうまく共存します。各ターミナルインスタンスは分離されています。

### Q: How do I use CCManager with multiple projects? / 複数のプロジェクトでCCManagerを使用するには？

A: CCManager automatically detects Git worktrees. Simply open Neovim in different worktree directories, and CCManager will manage sessions accordingly.

CCManagerは自動的にGit worktreeを検出します。異なるworktreeディレクトリでNeovimを開くだけで、CCManagerがセッションを適切に管理します。

### Q: Can I customize the CCManager UI? / CCManagerのUIをカスタマイズできますか？

A: The CCManager UI is managed by the CCManager application itself. For UI customization, please refer to the [CCManager documentation](https://github.com/kbwo/ccmanager).

CCManagerのUIはCCManagerアプリケーション自体によって管理されています。UIのカスタマイズについては、[CCManagerのドキュメント](https://github.com/kbwo/ccmanager)を参照してください。

### Q: The plugin doesn't work in my terminal / ターミナルでプラグインが動作しません

A: Ensure your terminal supports 256 colors and Unicode. Recommended terminals:
- **Linux/Mac**: Alacritty, Kitty, iTerm2
- **Windows**: Windows Terminal, WSLtty

ターミナルが256色とUnicodeをサポートしていることを確認してください。推奨ターミナル：
- **Linux/Mac**: Alacritty、Kitty、iTerm2
- **Windows**: Windows Terminal、WSLtty

## 🔌 API Documentation / APIドキュメント

### Public Functions / 公開関数

#### `require("ccmanager").setup(opts)`

Initialize ccmanager.nvim with the given options.

指定されたオプションでccmanager.nvimを初期化します。

**Parameters:**
- `opts` (table, optional): Configuration options

**Example:**
```lua
require("ccmanager").setup({
  keymap = "<leader>cm",
  window = { size = 0.3, position = "right" },
})
```

#### `require("ccmanager.terminal").toggle()`

Toggle the CCManager terminal window.

CCManagerターミナルウィンドウを切り替えます。

**Example:**
```lua
vim.keymap.set("n", "<leader>ct", function()
  require("ccmanager.terminal").toggle()
end)
```

#### `require("ccmanager.terminal").reset()`

Reset the terminal instance. Useful when CCManager gets stuck.

ターミナルインスタンスをリセットします。CCManagerが固まった時に便利です。

**Example:**
```lua
vim.api.nvim_create_user_command("CCManagerRestart", function()
  local terminal = require("ccmanager.terminal")
  terminal.reset()
  vim.wait(100)
  terminal.toggle()
end, {})
```

## 🤝 Contributing / 貢献

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

貢献を歓迎します！詳細は[貢献ガイド](CONTRIBUTING.md)をご覧ください。

## Credits

- [kbwo/ccmanager](https://github.com/kbwo/ccmanager) - The amazing CCManager TUI application
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) - Terminal management plugin for Neovim
- [folke/lazy.nvim](https://github.com/folke/lazy.nvim) - Modern plugin manager for Neovim

## Author

ishiooon

## License

MIT
