local M = {}
local utils = require("ccmanager.utils")
local state = require("ccmanager.state")

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
  M.config = config or {}
  -- デフォルト値を設定
  M.config.window = M.config.window or {
    size = 0.3,
    position = "bottom"
  }
  
  -- 状態管理の設定
  state.setup({
    terminal_per_buffer = M.config.terminal_per_buffer,
    terminal_per_dir = M.config.terminal_per_dir,
    cleanup_timeout = M.config.cleanup_timeout,
    debug = M.config.debug,
  })
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
  
  -- 状態管理から現在のコンテキストのターミナルを取得
  local terminal = state.get_terminal()
  
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
            vim.notify("CCManager: WSL2 clipboard not configured. See README.", vim.log.levels.WARN)
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
            local clipboard_content = vim.fn.getreg("+")
            if clipboard_content and clipboard_content ~= "" then
              -- WSL2環境での大量テキストペースト対策
              if utils.is_wsl() and #clipboard_content > 100 then
                -- 大きなテキストは分割してペースト
                local chunk_size = 50
                local chunks = {}
                for i = 1, #clipboard_content, chunk_size do
                  table.insert(chunks, clipboard_content:sub(i, i + chunk_size - 1))
                end
                
                -- 各チャンクを順番にペースト
                for i, chunk in ipairs(chunks) do
                  local escaped = vim.api.nvim_replace_termcodes(chunk, true, false, true)
                  vim.api.nvim_feedkeys(escaped, "n", false)
                  -- 小さな遅延を入れて処理を安定化
                  if i < #chunks then
                    vim.cmd("sleep 1m")
                  end
                end
              else
                -- 通常のペースト処理
                local escaped = vim.api.nvim_replace_termcodes(clipboard_content, true, false, true)
                vim.api.nvim_feedkeys(escaped, "n", false)
              end
            end
          end, { buffer = term.bufnr, desc = "Paste from clipboard" })
        end
      end,
      on_exit = function(term, job, exit_code)
        -- ターミナルが終了したら状態から削除
        if exit_code == 0 then
          state.destroy_terminal()
        end
      end,
    })
    
    -- 新しいターミナルを状態管理に登録
    state.set_terminal(terminal)
  end
  
  terminal:toggle()
end

-- 現在のターミナルを取得
function M.get_current()
  return state.get_terminal()
end

-- 現在のターミナルを破棄
function M.destroy_current()
  state.destroy_terminal()
end

-- すべてのターミナルを破棄
function M.destroy_all()
  state.destroy_all_terminals()
end

-- 状態をリセット
function M.reset()
  state.reset()
end

-- デバッグ用: 現在の状態を表示
function M.show_state()
  local current_state = state.get_state()
  local lines = {
    "CCManager Terminal State:",
    "========================",
  }
  
  for context_id, info in pairs(current_state.terminals) do
    table.insert(lines, string.format("Context: %s", context_id))
    table.insert(lines, string.format("  Is Open: %s", tostring(info.is_open)))
    table.insert(lines, string.format("  Has Instance: %s", tostring(info.has_instance)))
    if current_state.last_used[context_id] then
      local last_used = os.date("%Y-%m-%d %H:%M:%S", current_state.last_used[context_id] / 1000)
      table.insert(lines, string.format("  Last Used: %s", last_used))
    end
    table.insert(lines, "")
  end
  
  table.insert(lines, "Configuration:")
  table.insert(lines, string.format("  Per Buffer: %s", tostring(current_state.config.terminal_per_buffer)))
  table.insert(lines, string.format("  Per Directory: %s", tostring(current_state.config.terminal_per_dir)))
  table.insert(lines, string.format("  Cleanup Timeout: %d ms", current_state.config.cleanup_timeout))
  
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M