# CCManager.nvim テスト

このディレクトリにはCCManager.nvimのテストが含まれています。

## テストの実行

### 前提条件

テストを実行するには、[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)がインストールされている必要があります。

```bash
# packer.nvimを使用している場合
use 'nvim-lua/plenary.nvim'

# lazy.nvimを使用している場合
{ 'nvim-lua/plenary.nvim' }
```

### テストの実行方法

1. 全てのテストを実行:
```bash
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

2. 特定のテストファイルを実行:
```bash
nvim --headless -c "PlenaryBustedFile tests/ccmanager_spec.lua"
```

3. Neovim内から実行:
```vim
:PlenaryBustedDirectory tests/
```

## テストの構造

- `minimal_init.lua` - テスト用の最小限のNeovim設定
- `ccmanager_spec.lua` - メインのCCManagerモジュールのテスト
- `terminal_spec.lua` - ターミナル管理機能のテスト

## テストの書き方

plenary.nvimのテストフレームワークを使用しています。基本的な構造:

```lua
describe("機能名", function()
  it("期待される動作", function()
    -- テストコード
    assert.are.equal(expected, actual)
  end)
end)
```