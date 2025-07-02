# Contributing to ccmanager.nvim

Thank you for your interest in contributing to ccmanager.nvim! This document provides guidelines and instructions for contributing.

ccmanager.nvimへの貢献に興味を持っていただきありがとうございます！このドキュメントでは、貢献のためのガイドラインと手順を説明します。

## Getting Started / はじめに

### Prerequisites / 前提条件

- Neovim >= 0.11.0
- Git
- Basic knowledge of Lua and Neovim plugin development / LuaとNeovimプラグイン開発の基本的な知識

### Development Setup / 開発環境のセットアップ

1. Fork and clone the repository / リポジトリをフォークしてクローン:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ccmanager.nvim.git
   cd ccmanager.nvim
   ```

2. Create a new branch / 新しいブランチを作成:
   ```bash
   git checkout -b feature/your-feature-name
   # or / または
   git checkout -b fix/issue-number-description
   ```

3. Make your changes / 変更を加える

4. Run tests / テストを実行:
   ```bash
   # Install plenary.nvim if not already installed
   nvim --headless -c "PlenaryBustedDirectory tests/"
   ```

## Code Style / コードスタイル

### Lua Style Guide / Luaスタイルガイド

- Use 2 spaces for indentation / インデントは2スペース
- Use snake_case for variables and functions / 変数と関数名はsnake_case
- Use PascalCase for classes/modules / クラス/モジュール名はPascalCase
- Add comments for complex logic / 複雑なロジックにはコメントを追加
- Keep functions small and focused / 関数は小さく、単一の目的に集中

Example / 例:
```lua
local M = {}

-- This function does something important
-- この関数は重要な処理を行います
function M.important_function(param1, param2)
  local result = param1 + param2
  return result
end

return M
```

### Commit Messages / コミットメッセージ

Follow the conventional commit format / 従来のコミット形式に従ってください:

- `feat:` New feature / 新機能
- `fix:` Bug fix / バグ修正
- `docs:` Documentation changes / ドキュメントの変更
- `refactor:` Code refactoring / コードのリファクタリング
- `test:` Test additions or modifications / テストの追加または変更
- `chore:` Maintenance tasks / メンテナンスタスク

Example / 例:
```
feat: add support for custom window borders

- Add border option to window configuration
- Support all Neovim border styles
- Update documentation
```

## Testing / テスト

### Running Tests / テストの実行

```bash
# Run all tests / 全テストを実行
nvim --headless -c "PlenaryBustedDirectory tests/"

# Run specific test file / 特定のテストファイルを実行
nvim --headless -c "PlenaryBustedFile tests/terminal_spec.lua"
```

### Writing Tests / テストの書き方

All new features should include tests / 新機能にはすべてテストを含める必要があります:

```lua
describe("feature name", function()
  it("should do something", function()
    -- Arrange
    local input = "test"
    
    -- Act
    local result = my_function(input)
    
    -- Assert
    assert.equals("expected", result)
  end)
end)
```

## Pull Request Process / プルリクエストのプロセス

1. **Update documentation** / **ドキュメントを更新**
   - Update README.md if needed / 必要に応じてREADME.mdを更新
   - Add/update comments in code / コード内のコメントを追加/更新

2. **Ensure tests pass** / **テストが通ることを確認**
   - All existing tests must pass / 既存のテストがすべて通る必要があります
   - Add tests for new functionality / 新機能のテストを追加

3. **Create Pull Request** / **プルリクエストを作成**
   - Use a clear, descriptive title / 明確で説明的なタイトルを使用
   - Reference any related issues / 関連するissueを参照
   - Describe what changes you made and why / 何を変更し、なぜ変更したかを説明

### PR Template / PRテンプレート

```markdown
## Summary
Brief description of changes / 変更の簡単な説明

## Related Issue
Closes #XXX

## Changes
- Change 1
- Change 2

## Test Plan
- [ ] Manual testing completed / 手動テスト完了
- [ ] Unit tests added/updated / ユニットテストの追加/更新
- [ ] Documentation updated / ドキュメントの更新
```

## Reporting Issues / 問題の報告

### Bug Reports / バグレポート

When reporting bugs, please include / バグを報告する際は、以下を含めてください:

- Neovim version (`nvim --version`)
- ccmanager.nvim configuration / ccmanager.nvimの設定
- Steps to reproduce / 再現手順
- Expected behavior / 期待される動作
- Actual behavior / 実際の動作
- Error messages (if any) / エラーメッセージ（ある場合）

### Feature Requests / 機能リクエスト

For feature requests, please describe / 機能リクエストの場合は、以下を説明してください:

- The problem you're trying to solve / 解決しようとしている問題
- Your proposed solution / 提案する解決策
- Alternative solutions you've considered / 検討した代替案

## Community / コミュニティ

- Be respectful and constructive / 敬意を持って建設的に
- Help others when you can / できる時は他の人を助ける
- Ask questions if you're unsure / 不明な点は質問する

## License / ライセンス

By contributing, you agree that your contributions will be licensed under the MIT License.

貢献することにより、あなたの貢献がMITライセンスの下でライセンスされることに同意したものとみなされます。

Thank you for contributing! / 貢献ありがとうございます！