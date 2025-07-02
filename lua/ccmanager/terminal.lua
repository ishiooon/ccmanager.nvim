local M = {}
local terminal = nil
local utils = require("ccmanager.utils")
local error_handler = require("ccmanager.error")

local function check_nodejs()
  error_handler.debug("Checking for Node.js installation", "Dependencies")
  local result, err = error_handler.safe_execute("which node 2>/dev/null", nil, "Dependencies")
  if not result then
    error_handler.debug("Node.js check failed: " .. tostring(err), "Dependencies")
    return false
  end
  return result:gsub("%s+", "") ~= ""
end

local function check_ccmanager()
  error_handler.debug("Checking for ccmanager command", "Dependencies")
  local result, err = error_handler.safe_execute("which ccmanager 2>/dev/null || which npx 2>/dev/null", nil, "Dependencies")
  if not result then
    error_handler.debug("ccmanager check failed: " .. tostring(err), "Dependencies")
    return false
  end
  return result:gsub("%s+", "") ~= ""
end

local function validate_dependencies()
  if not check_nodejs() then
    error_handler.error("Node.js is not installed. Please install Node.js first.", "Dependencies")
    return false
  end
  
  if not check_ccmanager() then
    error_handler.error("'ccmanager' command not found. Please install it with 'npm install -g ccmanager'", "Dependencies")
    return false
  end
  
  error_handler.debug("All dependencies validated successfully", "Dependencies")
  return true
end

function M.setup(config)
  M.config = config or {}
  -- デフォルト値を設定
  M.config.window = M.config.window or {
    size = 0.3,
    position = "bottom"
  }
  -- デバッグモードの設定
  if M.config.debug then
    error_handler.set_debug(true)
  end
end

function M.toggle()
  error_handler.debug("Toggling CCManager terminal", "Terminal")
  
  if not validate_dependencies() then
    return
  end
  
  local toggleterm, err = error_handler.safe_require("toggleterm", "toggleterm.nvim is required. Please install it.", "Terminal")
  if not toggleterm then
    return
  end
  
  if not terminal then
    error_handler.debug("Creating new terminal instance", "Terminal")
    
    local terminal_module = error_handler.safe_require("toggleterm.terminal", "Failed to load toggleterm.terminal module", "Terminal")
    if not terminal_module then
      return
    end
    
    local Terminal = terminal_module.Terminal
    local create_terminal = function()
      return Terminal:new({
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
      on_exit = function(term, job, exit_code)
        -- プロセスの終了を監視
        if exit_code ~= 0 then
          error_handler.error(string.format("CCManager process exited with code %d", exit_code), "Process")
          -- 異常終了時はターミナルインスタンスをリセット
          terminal = nil
        else
          error_handler.debug("CCManager process exited normally", "Process")
        end
      end,
      on_open = function(term)
        -- 垂直分割の場合、ウィンドウサイズを明示的に設定
        if term.direction == "vertical" then
          local expected_width = math.max(math.floor(vim.o.columns * M.config.window.size), 30)
          error_handler.safe_api_call(function()
            vim.api.nvim_win_set_width(0, expected_width)
          end, "Failed to set window width", "Terminal")
        end
        
        -- WSL2環境での最適化
        if M.config.wsl_optimization and M.config.wsl_optimization.enabled and utils.is_wsl() then
          -- クリップボード設定をチェック
          if M.config.wsl_optimization.check_clipboard then
            local clipboard_ok, clipboard_result = pcall(utils.check_clipboard_config)
            if clipboard_ok and not clipboard_result then
              error_handler.warn("WSL2 clipboard not configured. See README for setup instructions.", "WSL2")
            elseif not clipboard_ok then
              error_handler.debug("Failed to check clipboard config: " .. tostring(clipboard_result), "WSL2")
            end
          end
          
          -- ペースト問題の修正
          if M.config.wsl_optimization.fix_paste then
            -- Bracketed Paste Modeを無効化
            vim.cmd("set t_BE=")
            -- ターミナルモードではpaste設定は使用できない
            -- また、modifiableはターミナルバッファでは常にtrueなので設定不要
            -- 代わりに、ターミナル固有のペースト問題を回避するための設定
            if vim.fn.has('nvim-0.8') == 1 then
              -- Neovim 0.8以降: ターミナルのペースト遅延を無効化
              vim.opt_local.ttimeoutlen = 0
            end
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
          -- ターミナルモードでの直接ペースト処理
          vim.keymap.set("t", M.config.terminal_keymaps.paste, function()
            local ok, clipboard_content = pcall(vim.fn.getreg, "+")
            if not ok then
              error_handler.error("Failed to access clipboard: " .. tostring(clipboard_content), "Clipboard")
              return
            end
            if clipboard_content and clipboard_content ~= "" then
              -- WSL2環境での大量テキストペースト対策
              if utils.is_wsl() and #clipboard_content > 15 then
                -- 大きなテキストは分割してペースト
                local chunk_size = 3
                local chunks = {}
                for i = 1, #clipboard_content, chunk_size do
                  table.insert(chunks, clipboard_content:sub(i, i + chunk_size - 1))
                end
                
                -- 各チャンクを順番にペースト
                for i, chunk in ipairs(chunks) do
                  local escaped = vim.api.nvim_replace_termcodes(chunk, true, false, true)
                  local feed_ok = error_handler.safe_api_call(function()
                    vim.api.nvim_feedkeys(escaped, "n", false)
                  end, "Failed to paste chunk " .. i, "Clipboard")
                  
                  if not feed_ok then
                    break
                  end
                  
                  -- 小さな遅延を入れて処理を安定化
                  if i < #chunks then
                    vim.cmd("sleep 0.5m")
                  end
                end
              else
                -- 通常のペースト処理
                local escaped = vim.api.nvim_replace_termcodes(clipboard_content, true, false, true)
                error_handler.safe_api_call(function()
                  vim.api.nvim_feedkeys(escaped, "n", false)
                end, "Failed to paste clipboard content", "Clipboard")
              end
            end
          end, { buffer = term.bufnr, desc = "Paste from clipboard" })
        end
      end,
      })
    end
    
    -- リトライ機能付きでターミナルを作成
    local created_terminal = error_handler.retry(create_terminal, {
      max_attempts = 3,
      delay = 100,
      context = "Terminal",
      error_msg = "Failed to create terminal after multiple attempts"
    })
    
    if created_terminal then
      terminal = created_terminal
      error_handler.info("CCManager terminal created successfully", "Terminal")
    else
      return
    end
  end
  
  -- ターミナルのトグル処理もエラーハンドリング
  local toggle_ok = error_handler.safe_api_call(function()
    terminal:toggle()
  end, "Failed to toggle terminal", "Terminal")
  
  if not toggle_ok then
    -- トグルに失敗した場合、ターミナルインスタンスをリセット
    terminal = nil
    error_handler.error("Terminal toggle failed. Please try again.", "Terminal")
  end
end

-- ターミナルインスタンスの状態を取得
function M.get_status()
  if not terminal then
    return "not_created"
  elseif terminal:is_open() then
    return "open"
  else
    return "closed"
  end
end

-- CCManagerプロセスを強制終了
function M.kill()
  if terminal then
    error_handler.info("Killing CCManager process", "Terminal")
    terminal:shutdown()
    terminal = nil
  else
    error_handler.warn("No active CCManager terminal to kill", "Terminal")
  end
end

-- ターミナルインスタンスをリセット
function M.reset()
  if terminal then
    if terminal:is_open() then
      terminal:close()
    end
    terminal = nil
    error_handler.info("CCManager terminal reset", "Terminal")
  end
end

return M
