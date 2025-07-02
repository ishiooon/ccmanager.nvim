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
      -- setup() を実行
      ccmanager.setup()
      
      -- キーマップが登録されているか確認
      local keymaps = vim.api.nvim_get_keymap("n")
      local found = false
      
      for _, keymap in ipairs(keymaps) do
        if keymap.lhs == " cm" then  -- <leader>はスペースになる
          found = true
          assert.are.equal("Toggle CCManager", keymap.desc)
          break
        end
      end
      
      -- 見つからない場合は、<leader>cmで再確認
      if not found then
        for _, keymap in ipairs(keymaps) do
          if keymap.lhs:match("cm$") then
            found = true
            break
          end
        end
      end
      
      assert.is_true(found, "Keymap <leader>cm was not registered")
    end)
  end)
end)