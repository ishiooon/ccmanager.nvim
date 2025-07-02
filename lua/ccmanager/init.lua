local M = {}

M.config = {
  keymap = "<leader>cm",
  window = {
    size = 0.3,
    position = "right",
  },
  command = "npx ccmanager",
  terminal_keymaps = {
    -- ターミナルモードから通常モードへの切り替え
    -- エスケープキーのマッピングを削除し、代わりに<C-q>を使用
    normal_mode = "<C-q>",
    -- ウィンドウ操作のキーマッピング
    window_nav = "<C-w>",
    -- ペースト用のキーマッピング（WSL2環境で有用）
    paste = "<C-S-v>",
  },
  -- WSL2環境での最適化
  wsl_optimization = {
    enabled = true,  -- WSL2環境での最適化を有効化
    check_clipboard = true,  -- クリップボード設定をチェック
    fix_paste = true,  -- ペースト問題の修正を適用
  },
  -- ターミナル状態管理
  terminal_per_buffer = false,  -- バッファごとにターミナルを管理
  terminal_per_dir = false,     -- ディレクトリごとにターミナルを管理
  cleanup_timeout = 30 * 60 * 1000,  -- 30分後に未使用ターミナルをクリーンアップ
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  local terminal = require("ccmanager.terminal")
  terminal.setup(M.config)
  
  vim.keymap.set("n", M.config.keymap, function()
    terminal.toggle()
  end, { desc = "Toggle CCManager" })
  
  -- 追加のコマンドを登録
  vim.api.nvim_create_user_command("CCManagerShowState", function()
    terminal.show_state()
  end, { desc = "Show CCManager terminal state" })
  
  vim.api.nvim_create_user_command("CCManagerDestroy", function()
    terminal.destroy_current()
    vim.notify("CCManager: Current terminal destroyed", vim.log.levels.INFO)
  end, { desc = "Destroy current CCManager terminal" })
  
  vim.api.nvim_create_user_command("CCManagerDestroyAll", function()
    terminal.destroy_all()
    vim.notify("CCManager: All terminals destroyed", vim.log.levels.INFO)
  end, { desc = "Destroy all CCManager terminals" })
  
  vim.api.nvim_create_user_command("CCManagerReset", function()
    terminal.reset()
    vim.notify("CCManager: State reset", vim.log.levels.INFO)
  end, { desc = "Reset CCManager state" })
end

return M
