describe("ccmanager error handling", function()
  local error_handler
  
  before_each(function()
    -- モジュールキャッシュをクリア
    package.loaded["ccmanager.error"] = nil
    error_handler = require("ccmanager.error")
  end)
  
  describe("logging functions", function()
    it("should log error messages", function()
      local notify_called = false
      local notify_msg = nil
      local notify_level = nil
      
      vim.notify = function(msg, level)
        notify_called = true
        notify_msg = msg
        notify_level = level
      end
      
      error_handler.error("Test error", "TestContext")
      
      assert.is_true(notify_called)
      assert.equals("[CCManager] [TestContext] Test error", notify_msg)
      assert.equals(vim.log.levels.ERROR, notify_level)
    end)
    
    it("should not log debug messages when debug is disabled", function()
      local notify_called = false
      
      vim.notify = function(msg, level)
        notify_called = true
      end
      
      error_handler.set_debug(false)
      error_handler.debug("Debug message", "TestContext")
      
      assert.is_false(notify_called)
    end)
    
    it("should log debug messages when debug is enabled", function()
      local notify_called = false
      
      vim.notify = function(msg, level)
        notify_called = true
      end
      
      error_handler.set_debug(true)
      error_handler.debug("Debug message", "TestContext")
      
      assert.is_true(notify_called)
    end)
  end)
  
  describe("safe_execute", function()
    it("should execute command successfully", function()
      local result, err = error_handler.safe_execute("echo 'test'")
      assert.is_not_nil(result)
      assert.is_nil(err)
      assert.equals("test\n", result)
    end)
    
    it("should handle command failure", function()
      -- Simulate error handling
      local notify_called = false
      vim.notify = function(msg, level)
        notify_called = true
      end
      
      local result, err = error_handler.safe_execute("/nonexistent/command")
      -- safe_executeは空文字列を返すことがある
      assert.is_true(result == nil or result == "")
      assert.is_not_nil(err)
      assert.is_true(notify_called)
    end)
  end)
  
  describe("retry", function()
    it("should succeed on first attempt", function()
      local attempt_count = 0
      local result = error_handler.retry(function()
        attempt_count = attempt_count + 1
        return "success"
      end)
      
      assert.equals("success", result)
      assert.equals(1, attempt_count)
    end)
    
    it("should retry on failure", function()
      local attempt_count = 0
      local result = error_handler.retry(function()
        attempt_count = attempt_count + 1
        if attempt_count < 3 then
          error("failed")
        end
        return "success"
      end, { max_attempts = 3, delay = 1 })
      
      assert.equals("success", result)
      assert.equals(3, attempt_count)
    end)
    
    it("should fail after max attempts", function()
      local attempt_count = 0
      local result = error_handler.retry(function()
        attempt_count = attempt_count + 1
        error("always fails")
      end, { max_attempts = 2, delay = 1 })
      
      assert.is_nil(result)
      assert.equals(2, attempt_count)
    end)
  end)
  
  describe("safe_require", function()
    it("should require existing module", function()
      -- ccmanager.utilsは存在するはず
      local module = error_handler.safe_require("ccmanager.utils")
      assert.is_not_nil(module)
    end)
    
    it("should handle missing module", function()
      local module, err = error_handler.safe_require("nonexistent.module")
      assert.is_nil(module)
      assert.is_not_nil(err)
    end)
  end)
  
  describe("safe_api_call", function()
    it("should execute API call successfully", function()
      local result = error_handler.safe_api_call(function()
        return vim.api.nvim_get_current_buf()
      end)
      
      assert.is_not_nil(result)
      assert.is_number(result)
    end)
    
    it("should handle API call failure", function()
      local result, err = error_handler.safe_api_call(function()
        vim.api.nvim_set_current_buf(-1) -- Invalid buffer
      end)
      
      assert.is_nil(result)
      assert.is_not_nil(err)
    end)
  end)
end)