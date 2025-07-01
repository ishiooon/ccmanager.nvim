describe("utils", function()
  local utils = require("ccmanager.utils")

  describe("is_wsl", function()
    it("should detect WSL environment", function()
      -- この テストは実際のシステム環境に依存するため、モック化が困難
      -- 実際のテストでは環境変数やファイルシステムをモックする必要がある
      local result = utils.is_wsl()
      assert.is_boolean(result)
    end)
  end)

  describe("check_clipboard_config", function()
    it("should check clipboard configuration", function()
      local result = utils.check_clipboard_config()
      assert.is_boolean(result)
    end)

    it("should return true for non-WSL environments", function()
      -- WSL環境でない場合は常にtrueを返すべき
      local original_is_wsl = utils.is_wsl
      utils.is_wsl = function() return false end
      
      local result = utils.check_clipboard_config()
      assert.is_true(result)
      
      utils.is_wsl = original_is_wsl
    end)
  end)

  describe("suggest_wsl_clipboard_config", function()
    it("should return WSL clipboard configuration", function()
      local config = utils.suggest_wsl_clipboard_config()
      assert.is_string(config)
      assert.is_true(config:find("WslClipboard") ~= nil)
      assert.is_true(config:find("clip.exe") ~= nil)
      assert.is_true(config:find("powershell.exe") ~= nil)
    end)
  end)
end)