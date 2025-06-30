local M = {}
local terminal = nil

function M.setup(config)
  M.config = config
end

function M.toggle()
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
        vim.cmd("startinsert!")
        -- エスケープキーはCCManagerのTUI操作に使用されるため、マッピングしない
        -- 代わりに設定可能なキーで通常モードへ切り替え
        if M.config.terminal_keymaps and M.config.terminal_keymaps.normal_mode then
          vim.keymap.set("t", M.config.terminal_keymaps.normal_mode, [[<C-\><C-n>]], { buffer = term.bufnr, desc = "Exit terminal mode" })
        end
        if M.config.terminal_keymaps and M.config.terminal_keymaps.window_nav then
          vim.keymap.set("t", M.config.terminal_keymaps.window_nav, [[<C-\><C-n><C-w>]], { buffer = term.bufnr, desc = "Window navigation" })
        end
      end,
    })
  end
  
  terminal:toggle()
end

return M