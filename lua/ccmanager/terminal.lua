local M = {}
local terminal = nil
local utils = require("ccmanager.utils")

local function check_nodejs()
  local handle = io.popen("which node 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

local function check_ccmanager()
  local handle = io.popen("which ccmanager 2>/dev/null || which npx 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

local function validate_dependencies()
  if not check_nodejs() then
    vim.notify("CCManager: Node.js is not installed. Please install Node.js first.", vim.log.levels.ERROR)
    return false
  end
  
  if not check_ccmanager() then
    vim.notify("CCManager: 'ccmanager' command not found. Please install it with 'npm install -g ccmanager'", vim.log.levels.ERROR)
    return false
  end
  
  return true
end

function M.setup(config)
  M.config = config
end

function M.toggle()
  if not validate_dependencies() then
    return
  end
  
  local ok, toggleterm = pcall(require, "toggleterm")
  if not ok then
    vim.notify("CCManager: toggleterm.nvim is required", vim.log.levels.ERROR)
    return
  end
  
  if not terminal then
    local Terminal = require("toggleterm.terminal").Terminal
    terminal = Terminal:new({
      cmd = M.config.command,
      dir = vim.fn.getcwd(),
      direction = (M.config.window.position == "right" or M.config.window.position == "left") and "vertical" or M.config.window.position,
      size = function(term)
        if term.direction == "vertical" then
          -- 垂直分割: 列数として計算し、最小幅を確保
          local calculated_size = math.floor(vim.o.columns * M.config.window.size)
          -- デバッグ情報を追加（本番環境では削除）
          -- vim.notify(string.format("CCManager: Calculated width: %d (columns: %d, size: %.2f)", calculated_size, vim.o.columns, M.config.window.size))
          return math.max(calculated_size, 30)  -- 最小幅を30に増加
        else
          -- 水平分割: 行数として計算
          return math.floor(vim.o.lines * M.config.window.size)
        end
      end,
      persist_size = false,  -- サイズの再計算を許可
      close_on_exit = true,
      hidden = false,
      on_open = function(term)
        -- 垂直分割の場合、ウィンドウサイズを明示的に設定
        if term.direction == "vertical" then
          local expected_width = math.max(math.floor(vim.o.columns * M.config.window.size), 30)
          vim.api.nvim_win_set_width(0, expected_width)
        end
        
        -- WSL2環境での最適化
        if M.config.wsl_optimization and M.config.wsl_optimization.enabled and utils.is_wsl() then
          -- クリップボード設定をチェック
          if M.config.wsl_optimization.check_clipboard and not utils.check_clipboard_config() then
            vim.notify("CCManager: WSL2環境でクリップボード設定が最適化されていません。READMEを参照してください。", vim.log.levels.WARN)
          end
          
          -- ペースト問題の修正
          if M.config.wsl_optimization.fix_paste then
            -- Bracketed Paste Modeを無効化
            vim.cmd("set t_BE=")
            -- ターミナルバッファでpaste設定を調整
            vim.bo[term.bufnr].paste = false
          end
        end
        
        vim.cmd("startinsert!")
        -- エスケープキーはCCManagerのTUI操作に使用されるため、マッピングしない
        -- 代わりに設定可能なキーで通常モードへ切り替え
        if M.config.terminal_keymaps and M.config.terminal_keymaps.normal_mode then
          vim.keymap.set("t", M.config.terminal_keymaps.normal_mode, [[<C-\><C-n>]], { buffer = term.bufnr, desc = "Exit terminal mode" })
        end
        if M.config.terminal_keymaps and M.config.terminal_keymaps.window_nav then
          vim.keymap.set("t", M.config.terminal_keymaps.window_nav, [[<C-\><C-n><C-w>]], { buffer = term.bufnr, desc = "Window navigation" })
        end
        -- ペースト用のキーマッピング（WSL2環境で有用）
        if M.config.terminal_keymaps and M.config.terminal_keymaps.paste then
          vim.keymap.set("t", M.config.terminal_keymaps.paste, [[<C-\><C-n>"+pi]], { buffer = term.bufnr, desc = "Paste from clipboard" })
        end
      end,
    })
  end
  
  terminal:toggle()
end

return M