local helper = require("spec.spec_helper")

describe("ccmanager.terminal", function()
  local terminal
  local mock_terminal_instance
  local mock_toggleterm
  
  before_each(function()
    -- キャッシュをクリア
    package.loaded["ccmanager.terminal"] = nil
    package.loaded["toggleterm"] = nil
    package.loaded["toggleterm.terminal"] = nil
    
    -- toggletermのモックを作成
    mock_terminal_instance = {
      toggle = helper.create_mock(),
      bufnr = 1234,
    }
    
    local Terminal = {
      new = function(self, opts)
        mock_terminal_instance.opts = opts
        return mock_terminal_instance
      end
    }
    
    mock_toggleterm = {
      terminal = {
        Terminal = Terminal
      }
    }
    
    -- モックを設定
    package.loaded["toggleterm"] = mock_toggleterm
    package.loaded["toggleterm.terminal"] = mock_toggleterm.terminal
    
    -- terminalモジュールを読み込み
    terminal = require("ccmanager.terminal")
  end)
  
  describe("setup()", function()
    it("設定を保存する", function()
      local config = {
        command = "test command",
        window = {
          position = "right",
          size = 0.4
        }
      }
      
      terminal.setup(config)
      
      assert.equals(config, terminal.config)
    end)
  end)
  
  describe("toggle()", function()
    local original_notify
    
    before_each(function()
      original_notify = vim.notify
      vim.notify = helper.create_mock()
      
      terminal.setup({
        command = "test command",
        window = {
          position = "right",
          size = 0.3
        }
      })
    end)
    
    after_each(function()
      vim.notify = original_notify
    end)
    
    it("toggletermが存在しない場合エラーメッセージを表示", function()
      package.loaded["toggleterm"] = nil
      
      terminal.toggle()
      
      assert.equals(1, vim.notify:call_count())
      local call_args = vim.notify.calls[1]
      assert.equals("CCManager: toggleterm.nvim is required", call_args[1])
      assert.equals(vim.log.levels.ERROR, call_args[2])
    end)
    
    it("初回呼び出し時にターミナルインスタンスを作成", function()
      terminal.toggle()
      
      assert.is_not_nil(mock_terminal_instance.opts)
      assert.equals("test command", mock_terminal_instance.opts.cmd)
      assert.equals(vim.fn.getcwd(), mock_terminal_instance.opts.dir)
      assert.equals("vertical", mock_terminal_instance.opts.direction)
      assert.equals(true, mock_terminal_instance.opts.close_on_exit)
      assert.equals(false, mock_terminal_instance.opts.hidden)
    end)
    
    it("ウィンドウサイズが正しく計算される（垂直分割）", function()
      vim.o.columns = 100
      
      terminal.toggle()
      
      local size_func = mock_terminal_instance.opts.size
      assert.equals(30, size_func()) -- 100 * 0.3 = 30
    end)
    
    it("ウィンドウサイズが正しく計算される（水平分割）", function()
      terminal.setup({
        command = "test command",
        window = {
          position = "bottom",
          size = 0.25
        }
      })
      
      vim.o.lines = 40
      
      terminal.toggle()
      
      local size_func = mock_terminal_instance.opts.size
      assert.equals(10, size_func()) -- 40 * 0.25 = 10
    end)
    
    it("左側配置でも垂直分割になる", function()
      terminal.setup({
        command = "test command",
        window = {
          position = "left",
          size = 0.3
        }
      })
      
      terminal.toggle()
      
      assert.equals("vertical", mock_terminal_instance.opts.direction)
    end)
    
    it("on_open関数でキーマップが設定される", function()
      local keymap_calls = {}
      vim.keymap.set = function(mode, lhs, rhs, opts)
        table.insert(keymap_calls, {mode = mode, lhs = lhs, rhs = rhs, opts = opts})
      end
      
      local cmd_calls = {}
      vim.cmd = function(cmd)
        table.insert(cmd_calls, cmd)
      end
      
      terminal.toggle()
      
      -- on_open関数を実行
      mock_terminal_instance.opts.on_open(mock_terminal_instance)
      
      assert.equals(1, #cmd_calls)
      assert.equals("startinsert!", cmd_calls[1])
      
      assert.equals(2, #keymap_calls)
      
      -- Escキーマップ
      assert.equals("t", keymap_calls[1].mode)
      assert.equals("<Esc>", keymap_calls[1].lhs)
      assert.equals([[<C-\><C-n>]], keymap_calls[1].rhs)
      assert.equals(1234, keymap_calls[1].opts.buffer)
      
      -- C-wキーマップ
      assert.equals("t", keymap_calls[2].mode)
      assert.equals("<C-w>", keymap_calls[2].lhs)
      assert.equals([[<C-\><C-n><C-w>]], keymap_calls[2].rhs)
      assert.equals(1234, keymap_calls[2].opts.buffer)
    end)
    
    it("2回目の呼び出しで既存のインスタンスをトグルする", function()
      -- 1回目
      terminal.toggle()
      assert.equals(1, mock_terminal_instance.toggle:call_count())
      
      -- 2回目
      terminal.toggle()
      assert.equals(2, mock_terminal_instance.toggle:call_count())
    end)
  end)
end)