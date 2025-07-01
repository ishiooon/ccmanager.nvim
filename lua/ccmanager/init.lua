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
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  local terminal = require("ccmanager.terminal")
  terminal.setup(M.config)
  
  vim.keymap.set("n", M.config.keymap, function()
    terminal.toggle()
  end, { desc = "Toggle CCManager" })
end

return M
