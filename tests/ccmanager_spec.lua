describe("ccmanager", function()
  local ccmanager
  
  before_each(function()
    -- toggleterm.nvimが存在しない可能性があるため、モックする
    if not package.loaded["toggleterm"] then
      package.loaded["toggleterm"] = {
        setup = function() end,
      }
    end
    if not package.loaded["toggleterm.terminal"] then
      package.loaded["toggleterm.terminal"] = {
        Terminal = {
          new = function(opts)
            return {
              toggle = function() end,
              is_open = function() return false end,
            }
          end,
        },
      }
    end
    
    -- モジュールをリロード
    package.loaded["ccmanager"] = nil
    package.loaded["ccmanager.init"] = nil
    package.loaded["ccmanager.terminal"] = nil
    package.loaded["ccmanager.utils"] = nil
    package.loaded["ccmanager.config"] = nil
    
    ccmanager = require("ccmanager")
  end)
  
  describe("setup()", function()
    it("デフォルト設定を持つ", function()
      assert.are.equal("<leader>cm", ccmanager.config.keymap)
      assert.are.equal(0.3, ccmanager.config.window.size)
      assert.are.equal("right", ccmanager.config.window.position)
      assert.are.equal("npx ccmanager", ccmanager.config.command)
    end)
    
    it("カスタム設定でオーバーライドできる", function()
      ccmanager.setup({
        keymap = "<leader>cc",
        window = {
          size = 0.5,
          position = "bottom",
        },
        command = "custom command",
      })
      
      assert.are.equal("<leader>cc", ccmanager.config.keymap)
      assert.are.equal(0.5, ccmanager.config.window.size)
      assert.are.equal("bottom", ccmanager.config.window.position)
      assert.are.equal("custom command", ccmanager.config.command)
    end)
    
    it("部分的な設定でもマージされる", function()
      ccmanager.setup({
        window = {
          size = 0.4,
        },
      })
      
      assert.are.equal(0.4, ccmanager.config.window.size)
      assert.are.equal("right", ccmanager.config.window.position) -- デフォルト値が保持される
    end)
    
    it("terminal_keymapsの設定ができる", function()
      ccmanager.setup({
        terminal_keymaps = {
          normal_mode = "<C-\\>",
          window_nav = "<C-w>",
        },
      })
      
      assert.are.equal("<C-\\>", ccmanager.config.terminal_keymaps.normal_mode)
      assert.are.equal("<C-w>", ccmanager.config.terminal_keymaps.window_nav)
    end)
    
    it("キーマップが登録される", function()
      local keymap_called = false
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        if mode == "n" and lhs == "<leader>cm" then
          keymap_called = true
          assert.are.equal("Toggle CCManager", opts.desc)
        end
      end
      
      ccmanager.setup()
      
      vim.keymap.set = original_keymap_set
      assert.is_true(keymap_called)
    end)
    
    it("無効な設定が修正される", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      ccmanager.setup({
        window = {
          size = 2.0,  -- 無効: 範囲外
          position = "invalid",  -- 無効: 無効な位置
        },
        command = "",  -- 無効: 空文字列
      })
      
      -- デフォルト値に修正される
      assert.are.equal(0.3, ccmanager.config.window.size)
      assert.are.equal("right", ccmanager.config.window.position)
      assert.are.equal("npx ccmanager", ccmanager.config.command)
      
      -- 警告メッセージが表示される
      assert.is_true(#notify_messages > 0)
      local found_validation_msg = false
      for _, msg in ipairs(notify_messages) do
        if msg:find("Invalid config") or msg:find("replaced with defaults") then
          found_validation_msg = true
          break
        end
      end
      assert.is_true(found_validation_msg)
    end)
    
    it("コマンドが登録される", function()
      local commands = {}
      local original_create_command = vim.api.nvim_create_user_command
      vim.api.nvim_create_user_command = function(name, callback, opts)
        commands[name] = { callback = callback, opts = opts }
      end
      
      ccmanager.setup()
      
      vim.api.nvim_create_user_command = original_create_command
      
      -- コマンドが登録されている
      assert.is_not_nil(commands["CCManagerShowConfig"])
      assert.is_not_nil(commands["CCManagerValidateConfig"])
    end)
  end)
end)