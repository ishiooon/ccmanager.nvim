describe("ccmanager", function()
  local ccmanager
  
  before_each(function()
    -- キャッシュをクリア
    package.loaded["ccmanager"] = nil
    package.loaded["ccmanager.init"] = nil
    package.loaded["ccmanager.terminal"] = nil
    
    -- プラグインを読み込み
    ccmanager = require("ccmanager")
  end)
  
  describe("setup()", function()
    it("デフォルト設定を持つ", function()
      assert.equals("<leader>cm", ccmanager.config.keymap)
      assert.equals(0.3, ccmanager.config.window.size)
      assert.equals("right", ccmanager.config.window.position)
      assert.equals("npx ccmanager", ccmanager.config.command)
    end)
    
    it("カスタム設定でデフォルトを上書きできる", function()
      ccmanager.setup({
        keymap = "<leader>cc",
        window = {
          size = 0.5,
          position = "bottom"
        }
      })
      
      assert.equals("<leader>cc", ccmanager.config.keymap)
      assert.equals(0.5, ccmanager.config.window.size)
      assert.equals("bottom", ccmanager.config.window.position)
      assert.equals("npx ccmanager", ccmanager.config.command) -- デフォルトのまま
    end)
    
    it("部分的な設定更新ができる", function()
      ccmanager.setup({
        window = {
          size = 0.4
        }
      })
      
      assert.equals("<leader>cm", ccmanager.config.keymap) -- デフォルトのまま
      assert.equals(0.4, ccmanager.config.window.size)
      assert.equals("right", ccmanager.config.window.position) -- デフォルトのまま
    end)
    
    it("nilを渡してもエラーにならない", function()
      assert.has_no.errors(function()
        ccmanager.setup(nil)
      end)
      
      assert.equals("<leader>cm", ccmanager.config.keymap)
    end)
    
    it("空のテーブルを渡してもエラーにならない", function()
      assert.has_no.errors(function()
        ccmanager.setup({})
      end)
      
      assert.equals("<leader>cm", ccmanager.config.keymap)
    end)
    
    it("キーマップが設定される", function()
      local keymap_calls = {}
      vim.keymap.set = function(mode, lhs, rhs, opts)
        table.insert(keymap_calls, {mode = mode, lhs = lhs, rhs = rhs, opts = opts})
      end
      
      ccmanager.setup()
      
      assert.equals(1, #keymap_calls)
      assert.equals("n", keymap_calls[1].mode)
      assert.equals("<leader>cm", keymap_calls[1].lhs)
      assert.equals("Toggle CCManager", keymap_calls[1].opts.desc)
    end)
  end)
end)