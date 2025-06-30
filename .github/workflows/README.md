# GitHub Actions CI/CD 解説

このディレクトリには、GitHub Actionsの設定ファイルが含まれています。GitHub Actionsは、コードの変更に応じて自動的にテストやデプロイを実行するCI/CD（継続的インテグレーション/継続的デリバリー）サービスです。

## ファイル構成

### `.github/workflows/test.yml`
自動テストを実行するための設定ファイルです。

## GitHub Actionsの基本概念

### 1. ワークフロー（Workflow）
- 1つまたは複数のジョブで構成される自動化されたプロセス
- YAMLファイルで定義される
- `.github/workflows/`ディレクトリに配置

### 2. イベント（Event）
ワークフローを起動するトリガー：
- `push`: コードがプッシュされた時
- `pull_request`: プルリクエストが作成/更新された時
- `schedule`: 定期的な実行
- `workflow_dispatch`: 手動実行

### 3. ジョブ（Job）
- ワークフロー内で実行される一連のステップ
- 並列または順次実行可能
- 異なる環境（OS）で実行可能

### 4. ステップ（Step）
- ジョブ内の個別のタスク
- コマンドの実行やアクションの使用

## test.ymlの詳細解説

### トリガー設定
```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
```
- `main`または`develop`ブランチへのプッシュ時
- `main`ブランチへのプルリクエスト時
にテストが自動実行されます。

### マトリックス戦略
```yaml
strategy:
  matrix:
    neovim_version: ['stable', 'nightly']
```
複数のNeovimバージョンでテストを実行し、互換性を確保します。

### 主要なステップ

1. **コードの取得**
   - `actions/checkout@v4`を使用してリポジトリのコードを取得

2. **Neovimのインストール**
   - `rhysd/action-setup-vim@v1`を使用
   - 安定版と開発版の両方でテスト

3. **依存関係のインストール**
   - plenary.nvim（テストフレームワーク）
   - toggleterm.nvim（プラグインの依存関係）

4. **テストの実行**
   - ヘッドレスモードでNeovimを起動
   - PlenaryBustedDirectoryコマンドでテストを実行

## ローカルでのテスト実行

GitHub Actionsで実行されるテストをローカルで確認する方法：

```bash
# 必要なプラグインをインストール
git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
git clone https://github.com/akinsho/toggleterm.nvim ~/.local/share/nvim/site/pack/vendor/start/toggleterm.nvim

# テストを実行
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" -c "qa!"
```

## ステータスバッジ

READMEにテストステータスを表示するには、以下のマークダウンを追加：

```markdown
![Tests](https://github.com/[ユーザー名]/ccmanager.nvim/workflows/Tests/badge.svg)
```

## トラブルシューティング

### テストが失敗する場合

1. **ログを確認**
   - GitHub Actionsのログで詳細なエラーメッセージを確認
   - 「Upload test results」ステップでアップロードされたファイルを確認

2. **ローカルで再現**
   - 同じコマンドをローカルで実行して問題を特定

3. **依存関係の確認**
   - すべての必要なプラグインがインストールされているか確認

## 参考リンク

- [GitHub Actions公式ドキュメント](https://docs.github.com/ja/actions)
- [Neovimプラグインのテスト方法](https://github.com/nvim-lua/plenary.nvim#plenarytest_harness)
- [GitHub Actionsのワークフロー構文](https://docs.github.com/ja/actions/using-workflows/workflow-syntax-for-github-actions)