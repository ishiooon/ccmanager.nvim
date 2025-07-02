describe("ccmanager config", function()
  local config
  
  before_each(function()
    -- モジュールキャッシュをクリア
    package.loaded["ccmanager.config"] = nil
    config = require("ccmanager.config")
  end)
  
  describe("validate", function()
    it("should accept valid window.size", function()
      local test_config = { window = { size = 0.5 } }
      local result = config.validate(test_config)
      assert.equals(0.5, result.window.size)
    end)
    
    it("should reject invalid window.size (not a number)", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      local test_config = { window = { size = "invalid" } }
      local result = config.validate(test_config)
      assert.is_true(#notify_messages > 0)
      local found = false
      for _, msg in ipairs(notify_messages) do
        if string.find(msg, "window.size must be a number") then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.equals(config.defaults.window.size, result.window.size)
    end)
    
    it("should reject invalid window.size (out of range)", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      local test_config = { window = { size = 1.5 } }
      local result = config.validate(test_config)
      assert.is_true(#notify_messages > 0)
      local found = false
      for _, msg in ipairs(notify_messages) do
        if string.find(msg, "window.size must be between 0 and 1") then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.equals(config.defaults.window.size, result.window.size)
    end)
    
    it("should accept valid window.position", function()
      local positions = {"right", "left", "float", "bottom", "top", "vertical", "horizontal"}
      for _, pos in ipairs(positions) do
        local test_config = { window = { position = pos } }
        local result = config.validate(test_config)
        assert.equals(pos, result.window.position)
      end
    end)
    
    it("should reject invalid window.position", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      local test_config = { window = { position = "invalid" } }
      local result = config.validate(test_config)
      assert.is_true(#notify_messages > 0)
      local found = false
      for _, msg in ipairs(notify_messages) do
        if string.find(msg, "window.position must be one of") then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.equals(config.defaults.window.position, result.window.position)
    end)
    
    it("should accept valid command", function()
      local test_config = { command = "npx ccmanager --debug" }
      local result = config.validate(test_config)
      assert.equals("npx ccmanager --debug", result.command)
    end)
    
    it("should reject empty command", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      local test_config = { command = "" }
      local result = config.validate(test_config)
      assert.is_true(#notify_messages > 0)
      local found = false
      for _, msg in ipairs(notify_messages) do
        if string.find(msg, "command cannot be empty") then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.equals(config.defaults.command, result.command)
    end)
    
    it("should accept valid keymap", function()
      local keymaps = {"<leader>cm", "<C-c>", "\\cm", "<F5>"}
      for _, km in ipairs(keymaps) do
        local test_config = { keymap = km }
        local result = config.validate(test_config)
        assert.equals(km, result.keymap)
      end
    end)
    
    it("should reject invalid keymap", function()
      local notify_called = false
      vim.notify = function(msg, level)
        notify_called = true
      end
      
      local test_config = { keymap = "" }
      local result = config.validate(test_config)
      assert.is_true(notify_called)
      assert.equals(config.defaults.keymap, result.keymap)
    end)
    
    it("should validate terminal_keymaps", function()
      local test_config = {
        terminal_keymaps = {
          normal_mode = "<C-\\>",
          window_nav = "<C-w>",
          paste = "<C-v>",
        }
      }
      local result = config.validate(test_config)
      assert.same(test_config.terminal_keymaps, result.terminal_keymaps)
    end)
    
    it("should reject invalid terminal_keymaps", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      local test_config = { terminal_keymaps = "invalid" }
      local result = config.validate(test_config)
      assert.is_true(#notify_messages > 0)
      local found = false
      for _, msg in ipairs(notify_messages) do
        if string.find(msg, "terminal_keymaps") then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.same(config.defaults.terminal_keymaps, result.terminal_keymaps)
    end)
    
    it("should validate wsl_optimization settings", function()
      local test_config = {
        wsl_optimization = {
          enabled = false,
          check_clipboard = false,
          fix_paste = true,
        }
      }
      local result = config.validate(test_config)
      assert.same(test_config.wsl_optimization, result.wsl_optimization)
    end)
    
    it("should reject invalid wsl_optimization.enabled", function()
      local notify_messages = {}
      vim.notify = function(msg, level)
        table.insert(notify_messages, msg)
      end
      
      local test_config = {
        wsl_optimization = {
          enabled = "yes",
        }
      }
      local result = config.validate(test_config)
      assert.is_true(#notify_messages > 0)
      local found = false
      for _, msg in ipairs(notify_messages) do
        if string.find(msg, "wsl_optimization.enabled must be a boolean") then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)
  end)
  
  describe("merge_with_defaults", function()
    it("should merge partial config with defaults", function()
      local test_config = {
        keymap = "<leader>x",
        window = {
          size = 0.4,
        }
      }
      
      local result = config.merge_with_defaults(test_config)
      
      -- カスタム値が保持される
      assert.equals("<leader>x", result.keymap)
      assert.equals(0.4, result.window.size)
      
      -- デフォルト値が使用される
      assert.equals(config.defaults.window.position, result.window.position)
      assert.equals(config.defaults.command, result.command)
      assert.same(config.defaults.terminal_keymaps, result.terminal_keymaps)
      assert.same(config.defaults.wsl_optimization, result.wsl_optimization)
    end)
    
    it("should handle nil config", function()
      local result = config.merge_with_defaults(nil)
      assert.same(config.defaults, result)
    end)
    
    it("should handle empty config", function()
      local result = config.merge_with_defaults({})
      assert.same(config.defaults, result)
    end)
  end)
  
  describe("show_config", function()
    it("should display configuration summary", function()
      local notify_called = false
      local notify_msg = nil
      
      vim.notify = function(msg, level)
        notify_called = true
        notify_msg = msg
      end
      
      config.show_config(config.defaults)
      
      assert.is_true(notify_called)
      assert.truthy(string.find(notify_msg, "CCManager Configuration"))
      assert.truthy(string.find(notify_msg, "Keymap:"))
      assert.truthy(string.find(notify_msg, "Window:"))
      assert.truthy(string.find(notify_msg, "Terminal Keymaps:"))
      assert.truthy(string.find(notify_msg, "WSL2 Optimization:"))
    end)
  end)
end)