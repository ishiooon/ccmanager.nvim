describe("ccmanager.terminal", function()
  local terminal
  
  before_each(function()
    -- モジュールをリロード
    package.loaded["ccmanager.terminal"] = nil
    terminal = require("ccmanager.terminal")
  end)
  
  describe("setup()", function()
    it("設定を保存する", function()
      local config = {
        command = "test command",
        window = {
          size = 0.4,
          position = "bottom",
        },
      }
      
      terminal.setup(config)
      assert.are.same(config, terminal.config)
    end)
  end)
  
  describe("toggle()", function()
    it("Node.jsがインストールされていない場合エラーメッセージを表示", function()
      -- io.popenのモック（Node.jsが見つからない）
      local original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
      
      local notify_called = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("Node.js is not installed") and level == vim.log.levels.ERROR then
          notify_called = true
        end
      end
      
      terminal.setup({ 
        command = "test",
        window = {
          size = 0.3,
          position = "bottom"
        }
      })
      terminal.toggle()
      
      io.popen = original_popen
      vim.notify = original_notify
      assert.is_true(notify_called)
    end)
    
    it("ccmanagerコマンドが存在しない場合エラーメッセージを表示", function()
      -- io.popenのモック（Node.jsは存在、ccmanager/npxは存在しない）
      local original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "/usr/bin/node" end,
            close = function() end
          }
        elseif cmd:match("which ccmanager") or cmd:match("which npx") then
          return {
            read = function() return "" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
      
      local notify_called = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("'ccmanager' command not found") and level == vim.log.levels.ERROR then
          notify_called = true
        end
      end
      
      terminal.setup({ 
        command = "test",
        window = {
          size = 0.3,
          position = "bottom"
        }
      })
      terminal.toggle()
      
      io.popen = original_popen
      vim.notify = original_notify
      assert.is_true(notify_called)
    end)
    
    it("toggleterm.nvimが存在しない場合エラーメッセージを表示", function()
      -- io.popenのモック（依存関係はOK）
      local original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "/usr/bin/node" end,
            close = function() end
          }
        elseif cmd:match("which ccmanager") or cmd:match("which npx") then
          return {
            read = function() return "/usr/bin/npx" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
      
      -- toggletermの読み込みが失敗するようにモック
      package.loaded["toggleterm"] = nil
      package.loaded["toggleterm.terminal"] = nil
      
      -- requireをモックして、toggletermの読み込みだけ失敗させる
      local original_require = require
      _G.require = function(module)
        if module == "toggleterm" then
          error("module 'toggleterm' not found")
        end
        return original_require(module)
      end
      
      local notify_called = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("toggleterm.nvim is required") and level == vim.log.levels.ERROR then
          notify_called = true
        end
      end
      
      terminal.setup({ 
        command = "test",
        window = {
          size = 0.3,
          position = "bottom"
        }
      })
      terminal.toggle()
      
      io.popen = original_popen
      vim.notify = original_notify
      _G.require = original_require
      assert.is_true(notify_called)
    end)
    
    it("ターミナルが作成される", function()
      -- io.popenのモック（依存関係はOK）
      local original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "/usr/bin/node" end,
            close = function() end
          }
        elseif cmd:match("which ccmanager") or cmd:match("which npx") then
          return {
            read = function() return "/usr/bin/npx" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
      
      -- toggletermモジュールのモック
      local terminal_new_called = false
      local terminal_toggle_called = false
      local mock_terminal = {
        toggle = function() terminal_toggle_called = true end
      }
      
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            terminal_new_called = true
            assert.are.equal("test command", opts.cmd)
            assert.are.equal(true, opts.close_on_exit)
            assert.are.equal(false, opts.hidden)
            assert.is_function(opts.size)
            assert.is_function(opts.on_open)
            return mock_terminal
          end
        }
      }
      
      terminal.setup({
        command = "test command",
        window = {
          size = 0.3,
          position = "right",
        },
      })
      terminal.toggle()
      
      io.popen = original_popen
      assert.is_true(terminal_new_called)
      assert.is_true(terminal_toggle_called)
    end)
  end)
  
  describe("ウィンドウサイズ計算", function()
    local original_popen
    
    before_each(function()
      -- io.popenのモック（依存関係はOK）
      original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "/usr/bin/node" end,
            close = function() end
          }
        elseif cmd:match("which ccmanager") or cmd:match("which npx") then
          return {
            read = function() return "/usr/bin/npx" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
    end)
    
    after_each(function()
      io.popen = original_popen
    end)
    
    it("垂直分割の場合は列数を計算", function()
      -- toggletermモジュールのモック
      local size_function
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            size_function = opts.size
            return { toggle = function() end }
          end
        }
      }
      
      terminal.setup({
        command = "test",
        window = {
          size = 0.3,
          position = "right",
        },
      })
      terminal.toggle()
      
      -- vim.o.columnsのモック
      vim.o.columns = 100
      local term_mock = { direction = "vertical" }
      local calculated_size = size_function(term_mock)
      
      assert.are.equal(30, calculated_size) -- 100 * 0.3 = 30
    end)
    
    it("垂直分割で最小幅を確保", function()
      -- toggletermモジュールのモック
      local size_function
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            size_function = opts.size
            return { toggle = function() end }
          end
        }
      }
      
      terminal.setup({
        command = "test",
        window = {
          size = 0.1,
          position = "left",
        },
      })
      terminal.toggle()
      
      -- 小さいウィンドウでのテスト
      vim.o.columns = 50
      local term_mock = { direction = "vertical" }
      local calculated_size = size_function(term_mock)
      
      assert.are.equal(30, calculated_size) -- 最小値の30を確保
    end)
    
    it("水平分割の場合は行数を計算", function()
      -- toggletermモジュールのモック
      local size_function
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            size_function = opts.size
            return { toggle = function() end }
          end
        }
      }
      
      terminal.setup({
        command = "test",
        window = {
          size = 0.3,
          position = "bottom",
        },
      })
      terminal.toggle()
      
      -- vim.o.linesのモック
      vim.o.lines = 50
      local term_mock = { direction = "horizontal" }
      local calculated_size = size_function(term_mock)
      
      assert.are.equal(15, calculated_size) -- 50 * 0.3 = 15
    end)
  end)
  
  describe("キーマッピング", function()
    local original_popen
    
    before_each(function()
      -- io.popenのモック（依存関係はOK）
      original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "/usr/bin/node" end,
            close = function() end
          }
        elseif cmd:match("which ccmanager") or cmd:match("which npx") then
          return {
            read = function() return "/usr/bin/npx" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
    end)
    
    after_each(function()
      io.popen = original_popen
    end)
    
    it("on_open関数でキーマップが設定される", function()
      -- toggletermモジュールのモック
      local on_open_function
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            on_open_function = opts.on_open
            return { toggle = function() end }
          end
        }
      }
      
      terminal.setup({
        command = "test",
        window = { size = 0.3, position = "right" },
        terminal_keymaps = {
          normal_mode = "<C-q>",
          window_nav = "<C-w>",
        },
      })
      terminal.toggle()
      
      -- キーマップのモック
      local keymaps_set = {}
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        table.insert(keymaps_set, {mode = mode, lhs = lhs, rhs = rhs, opts = opts})
      end
      
      -- startinsertのモック
      local original_cmd = vim.cmd
      vim.cmd = function(cmd) end
      
      -- on_openを実行
      local term_mock = { bufnr = 123 }
      on_open_function(term_mock)
      
      vim.keymap.set = original_keymap_set
      vim.cmd = original_cmd
      
      -- キーマップが設定されたか確認
      assert.are.equal(2, #keymaps_set)
      assert.are.equal("t", keymaps_set[1].mode)
      assert.are.equal("<C-q>", keymaps_set[1].lhs)
      assert.are.equal(123, keymaps_set[1].opts.buffer)
      assert.are.equal("t", keymaps_set[2].mode)
      assert.are.equal("<C-w>", keymaps_set[2].lhs)
      assert.are.equal(123, keymaps_set[2].opts.buffer)
    end)
  end)
  
  describe("WSL2環境での最適化", function()
    local original_popen
    
    before_each(function()
      -- io.popenのモック（依存関係はOK）
      original_popen = io.popen
      io.popen = function(cmd)
        if cmd:match("which node") then
          return {
            read = function() return "/usr/bin/node" end,
            close = function() end
          }
        elseif cmd:match("which ccmanager") or cmd:match("which npx") then
          return {
            read = function() return "/usr/bin/npx" end,
            close = function() end
          }
        end
        return original_popen(cmd)
      end
    end)
    
    after_each(function()
      io.popen = original_popen
    end)
    
    it("WSL2環境でペースト修正が適用される", function()
      -- utilsモジュールのモック
      package.loaded["ccmanager.utils"] = {
        is_wsl = function() return true end,
        check_clipboard_config = function() return true end
      }
      
      -- on_open関数の実行を確認するためのフラグ
      local on_open_called = false
      local t_be_disabled = false
      local opt_local_set = false
      
      -- vim.cmdのモック
      local original_cmd = vim.cmd
      vim.cmd = function(cmd) 
        if type(cmd) == "string" and cmd:match("set t_BE=") then
          t_be_disabled = true
        elseif type(cmd) == "string" and cmd:match("startinsert") then
          -- startinsertも実行されることを確認
          on_open_called = true
        end
      end
      
      -- vim.opt_localのモック
      local original_opt_local = vim.opt_local
      vim.opt_local = setmetatable({}, {
        __newindex = function(t, k, v)
          if k == "ttimeoutlen" and v == 0 then
            opt_local_set = true
          end
        end
      })
      
      -- vim.fn.hasのモック (Neovim 0.8以降として)
      local original_has = vim.fn.has
      vim.fn.has = function(feature)
        if feature == 'nvim-0.8' then
          return 1
        end
        return original_has(feature)
      end
      
      -- toggletermモジュールのモック
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            -- on_open関数を手動で呼び出して設定を適用
            local term_mock = { bufnr = 123, direction = "horizontal" }
            opts.on_open(term_mock)
            return { toggle = function() end }
          end
        }
      }
      
      -- terinalモジュールをリロードして新しいモックを使用
      package.loaded["ccmanager.terminal"] = nil
      terminal = require("ccmanager.terminal")
      
      terminal.setup({
        command = "test",
        window = { size = 0.3, position = "bottom" },
        wsl_optimization = {
          enabled = true,
          fix_paste = true,
          check_clipboard = false
        }
      })
      terminal.toggle()
      
      -- モックを元に戻す
      vim.cmd = original_cmd
      vim.opt_local = original_opt_local
      vim.fn.has = original_has
      
      -- アサーション
      assert.is_true(on_open_called, "on_open should be called")
      assert.is_true(t_be_disabled, "t_BE should be disabled")
      assert.is_true(opt_local_set, "ttimeoutlen should be set to 0")
    end)
    
    it("WSL2環境でペーストキーマッピングが設定される", function()
      -- utilsモジュールのモック
      package.loaded["ccmanager.utils"] = {
        is_wsl = function() return true end,
        check_clipboard_config = function() return true end
      }
      
      -- キーマップ設定を記録
      local paste_keymap_set = false
      local paste_function = nil
      
      -- vim.keymap.setのモック
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        if mode == "t" and lhs == "<C-S-v>" then
          paste_keymap_set = true
          paste_function = rhs
        end
      end
      
      -- vim.cmdのモック
      local original_cmd = vim.cmd
      vim.cmd = function(cmd) end
      
      -- vim.opt_localのモック
      local original_opt_local = vim.opt_local
      vim.opt_local = setmetatable({}, {
        __newindex = function(t, k, v) end
      })
      
      -- vim.fn.hasのモック
      local original_has = vim.fn.has
      vim.fn.has = function(feature)
        if feature == 'nvim-0.8' then
          return 1
        end
        return original_has(feature)
      end
      
      -- toggletermモジュールのモック
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            local term_mock = { bufnr = 123, direction = "horizontal" }
            opts.on_open(term_mock)
            return { toggle = function() end }
          end
        }
      }
      
      -- terminalモジュールをリロード
      package.loaded["ccmanager.terminal"] = nil
      terminal = require("ccmanager.terminal")
      
      terminal.setup({
        command = "test",
        window = { size = 0.3, position = "bottom" },
        terminal_keymaps = {
          paste = "<C-S-v>"
        },
        wsl_optimization = {
          enabled = true,
          fix_paste = true
        }
      })
      terminal.toggle()
      
      -- モックを元に戻す
      vim.keymap.set = original_keymap_set
      vim.cmd = original_cmd
      vim.opt_local = original_opt_local
      vim.fn.has = original_has
      
      -- アサーション
      assert.is_true(paste_keymap_set, "Paste keymap should be set")
      assert.is_function(paste_function, "Paste function should be a function")
    end)
    
    it("ペースト機能が正しく動作する", function()
      -- utilsモジュールのモック
      package.loaded["ccmanager.utils"] = {
        is_wsl = function() return false end,  -- 通常環境でテスト
        check_clipboard_config = function() return true end
      }
      
      -- ペースト関数を保存
      local paste_function = nil
      
      -- vim.keymap.setのモック
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        if mode == "t" and lhs == "<C-S-v>" then
          paste_function = rhs
        end
      end
      
      -- vim.fn.getregのモック（クリップボードの内容）
      local original_getreg = vim.fn.getreg
      vim.fn.getreg = function(reg)
        if reg == "+" then
          return "test clipboard content"
        end
        return original_getreg(reg)
      end
      
      -- vim.api.nvim_replace_termcodesのモック
      local original_replace_termcodes = vim.api.nvim_replace_termcodes
      vim.api.nvim_replace_termcodes = function(str, from_part, do_lt, special)
        return str  -- そのまま返す
      end
      
      -- vim.api.nvim_feedkeysのモック
      local feedkeys_called = false
      local feedkeys_content = nil
      local original_feedkeys = vim.api.nvim_feedkeys
      vim.api.nvim_feedkeys = function(keys, mode, escape_csi)
        feedkeys_called = true
        feedkeys_content = keys
      end
      
      -- その他のモック
      local original_cmd = vim.cmd
      vim.cmd = function(cmd) end
      
      local original_opt_local = vim.opt_local
      vim.opt_local = setmetatable({}, {
        __newindex = function(t, k, v) end
      })
      
      -- toggletermモジュールのモック
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            local term_mock = { bufnr = 123, direction = "horizontal" }
            opts.on_open(term_mock)
            return { toggle = function() end }
          end
        }
      }
      
      -- terminalモジュールをリロード
      package.loaded["ccmanager.terminal"] = nil
      terminal = require("ccmanager.terminal")
      
      terminal.setup({
        command = "test",
        window = { size = 0.3, position = "bottom" },
        terminal_keymaps = {
          paste = "<C-S-v>"
        }
      })
      terminal.toggle()
      
      -- ペースト関数を実行
      if paste_function then
        paste_function()
      end
      
      -- モックを元に戻す
      vim.keymap.set = original_keymap_set
      vim.fn.getreg = original_getreg
      vim.api.nvim_replace_termcodes = original_replace_termcodes
      vim.api.nvim_feedkeys = original_feedkeys
      vim.cmd = original_cmd
      vim.opt_local = original_opt_local
      
      -- アサーション
      assert.is_true(feedkeys_called, "nvim_feedkeys should be called")
      assert.are.equal("test clipboard content", feedkeys_content, "Clipboard content should be pasted")
    end)
    
    it("WSL2環境で大量テキストが分割してペーストされる", function()
      -- utilsモジュールのモック
      package.loaded["ccmanager.utils"] = {
        is_wsl = function() return true end,  -- WSL2環境
        check_clipboard_config = function() return true end
      }
      
      -- ペースト関数を保存
      local paste_function = nil
      
      -- vim.keymap.setのモック
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        if mode == "t" and lhs == "<C-S-v>" then
          paste_function = rhs
        end
      end
      
      -- 大量のテキストを生成（150文字）
      local large_text = string.rep("abcdefghij", 15)  -- 150文字（30文字ずつ5チャンクに分割される）
      
      -- vim.fn.getregのモック
      local original_getreg = vim.fn.getreg
      vim.fn.getreg = function(reg)
        if reg == "+" then
          return large_text
        end
        return original_getreg(reg)
      end
      
      -- vim.fn.systemのモック（WSL2でのクリップボード取得）
      local original_system = vim.fn.system
      vim.fn.system = function(cmd)
        if cmd:match("powershell.exe") then
          return large_text
        end
        return original_system(cmd)
      end
      
      -- vim.api.nvim_replace_termcodesのモック
      local original_replace_termcodes = vim.api.nvim_replace_termcodes
      vim.api.nvim_replace_termcodes = function(str, from_part, do_lt, special)
        return str
      end
      
      -- vim.api.nvim_feedkeysのモック
      local feedkeys_calls = {}
      local original_feedkeys = vim.api.nvim_feedkeys
      vim.api.nvim_feedkeys = function(keys, mode, escape_csi)
        table.insert(feedkeys_calls, keys)
      end
      
      -- vim.cmdのモック（sleepとredrawコマンドを記録）
      local sleep_count = 0
      local redraw_count = 0
      local original_cmd = vim.cmd
      vim.cmd = function(cmd)
        if type(cmd) == "string" then
          if cmd:match("sleep") then
            sleep_count = sleep_count + 1
          elseif cmd:match("redraw") then
            redraw_count = redraw_count + 1
          end
        end
      end
      
      -- その他のモック
      local original_opt_local = vim.opt_local
      vim.opt_local = setmetatable({}, {
        __newindex = function(t, k, v) end
      })
      
      -- toggletermモジュールのモック
      package.loaded["toggleterm"] = {}
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(self, opts)
            local term_mock = { bufnr = 123, direction = "horizontal" }
            opts.on_open(term_mock)
            return { toggle = function() end }
          end
        }
      }
      
      -- terminalモジュールをリロード
      package.loaded["ccmanager.terminal"] = nil
      terminal = require("ccmanager.terminal")
      
      terminal.setup({
        command = "test",
        window = { size = 0.3, position = "bottom" },
        terminal_keymaps = {
          paste = "<C-S-v>"
        },
        wsl_optimization = {
          enabled = true
        }
      })
      terminal.toggle()
      
      -- ペースト関数を実行
      if paste_function then
        paste_function()
      end
      
      -- モックを元に戻す
      vim.keymap.set = original_keymap_set
      vim.fn.getreg = original_getreg
      vim.fn.system = original_system
      vim.api.nvim_replace_termcodes = original_replace_termcodes
      vim.api.nvim_feedkeys = original_feedkeys
      vim.cmd = original_cmd
      vim.opt_local = original_opt_local
      
      -- アサーション
      assert.is_true(#feedkeys_calls > 1, "Should be split into multiple chunks")
      assert.are.equal(5, #feedkeys_calls, "150 chars should be split into 5 chunks of 30")
      assert.are.equal(4, sleep_count, "Should have 4 sleep calls between chunks")
      assert.are.equal(4, redraw_count, "Should have 4 redraw calls between chunks")
      
      -- 分割されたテキストを結合して元のテキストと一致するか確認
      local combined = table.concat(feedkeys_calls, "")
      assert.are.equal(large_text, combined, "Combined chunks should equal original text")
    end)
  end)
end)