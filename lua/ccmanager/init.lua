local M = {}

local error_handler = require("ccmanager.error")

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
  error_handler.debug("Setting up CCManager", "Setup")
  
  -- 設定のマージ
  local merge_ok = error_handler.safe_api_call(function()
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  end, "Failed to merge configuration", "Setup")
  
  if not merge_ok then
    return
  end
  
  -- terminalモジュールの読み込み
  local terminal = error_handler.safe_require("ccmanager.terminal", "Failed to load terminal module", "Setup")
  if not terminal then
    return
  end
  
  -- terminalの設定
  local setup_ok = error_handler.safe_api_call(function()
    terminal.setup(M.config)
  end, "Failed to setup terminal", "Setup")
  
  if not setup_ok then
    return
  end
  
  -- キーマップの設定
  local keymap_ok = error_handler.safe_api_call(function()
    vim.keymap.set("n", M.config.keymap, function()
      terminal.toggle()
    end, { desc = "Toggle CCManager" })
  end, "Failed to set keymap", "Setup")
  
  if keymap_ok then
    error_handler.info("CCManager setup completed successfully", "Setup")
  end
  
  -- 追加のコマンドを登録
  error_handler.safe_api_call(function()
    -- デバッグモードの切り替え
    vim.api.nvim_create_user_command("CCManagerDebug", function(args)
      local enabled = args.args == "on" or args.args == "true" or args.args == "1"
      error_handler.set_debug(enabled)
    end, { nargs = 1, complete = function() return {"on", "off"} end, desc = "Toggle CCManager debug mode" })
    
    -- ステータス表示
    vim.api.nvim_create_user_command("CCManagerStatus", function()
      local status = terminal.get_status()
      error_handler.info("Terminal status: " .. status, "Command")
    end, { desc = "Show CCManager terminal status" })
    
    -- 強制リセット
    vim.api.nvim_create_user_command("CCManagerReset", function()
      terminal.reset()
    end, { desc = "Reset CCManager terminal instance" })
    
    -- プロセスの強制終了
    vim.api.nvim_create_user_command("CCManagerKill", function()
      terminal.kill()
    end, { desc = "Kill CCManager process" })
  end, "Failed to create user commands", "Setup")
end

return M
