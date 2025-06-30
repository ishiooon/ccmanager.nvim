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
