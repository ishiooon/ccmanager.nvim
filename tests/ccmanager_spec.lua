describe("ccmanager", function()
  local ccmanager
  
  before_each(function()
    -- モジュールをリロード
    package.loaded["ccmanager"] = nil
    package.loaded["ccmanager.init"] = nil
    package.loaded["ccmanager.terminal"] = nil
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
  end)
end)