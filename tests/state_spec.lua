describe("ccmanager state", function()
  local state
  
  before_each(function()
    -- モジュールキャッシュをクリア
    package.loaded["ccmanager.state"] = nil
    state = require("ccmanager.state")
    
    -- 状態をリセット
    state.reset()
  end)
  
  describe("setup", function()
    it("should set default configuration", function()
      state.setup()
      local current_state = state.get_state()
      
      assert.is_false(current_state.config.terminal_per_buffer)
      assert.is_false(current_state.config.terminal_per_dir)
      assert.is_false(current_state.config.debug)
      assert.equals(30 * 60 * 1000, current_state.config.cleanup_timeout)
    end)
    
    it("should accept custom configuration", function()
      state.setup({
        terminal_per_buffer = true,
        terminal_per_dir = false,
        cleanup_timeout = 60000,
        debug = true,
      })
      
      local current_state = state.get_state()
      assert.is_true(current_state.config.terminal_per_buffer)
      assert.is_false(current_state.config.terminal_per_dir)
      assert.is_true(current_state.config.debug)
      assert.equals(60000, current_state.config.cleanup_timeout)
    end)
  end)
  
  describe("terminal management", function()
    before_each(function()
      state.setup({ terminal_per_buffer = false })
    end)
    
    it("should store and retrieve terminal instance", function()
      local mock_terminal = { id = "test", is_open = function() return true end }
      
      state.set_terminal(mock_terminal)
      local retrieved = state.get_terminal()
      
      assert.equals(mock_terminal, retrieved)
    end)
    
    it("should return nil for non-existent terminal", function()
      local retrieved = state.get_terminal("non_existent")
      assert.is_nil(retrieved)
    end)
    
    it("should destroy terminal", function()
      local mock_terminal = {
        id = "test",
        is_open = function() return false end,
        close = function() end,
        shutdown = function() end,
      }
      
      state.set_terminal(mock_terminal)
      state.destroy_terminal()
      
      local retrieved = state.get_terminal()
      assert.is_nil(retrieved)
    end)
    
    it("should close open terminal before destroying", function()
      local close_called = false
      local shutdown_called = false
      
      local mock_terminal = {
        is_open = function() return true end,
        close = function() close_called = true end,
        shutdown = function() shutdown_called = true end,
      }
      
      state.set_terminal(mock_terminal)
      state.destroy_terminal()
      
      assert.is_true(close_called)
      assert.is_true(shutdown_called)
    end)
    
    it("should destroy all terminals", function()
      local terminals = {}
      for i = 1, 3 do
        terminals[i] = {
          id = "test" .. i,
          is_open = function() return false end,
          shutdown = function() end,
        }
        state.set_terminal(terminals[i], "context_" .. i)
      end
      
      state.destroy_all_terminals()
      
      for i = 1, 3 do
        assert.is_nil(state.get_terminal("context_" .. i))
      end
    end)
  end)
  
  describe("context management", function()
    it("should use global context by default", function()
      state.setup({ terminal_per_buffer = false, terminal_per_dir = false })
      
      local terminal1 = { id = "test1" }
      state.set_terminal(terminal1)
      
      -- 異なる場所から取得しても同じターミナルが返る
      local retrieved = state.get_terminal()
      assert.equals(terminal1, retrieved)
    end)
    
    it("should use buffer-specific context when enabled", function()
      state.setup({ terminal_per_buffer = true })
      
      -- バッファ1のターミナル
      local terminal1 = { id = "test1" }
      state.set_terminal(terminal1, "buf_1")
      
      -- バッファ2のターミナル
      local terminal2 = { id = "test2" }
      state.set_terminal(terminal2, "buf_2")
      
      -- それぞれ独立して管理される
      assert.equals(terminal1, state.get_terminal("buf_1"))
      assert.equals(terminal2, state.get_terminal("buf_2"))
      assert.not_equals(terminal1, terminal2)
    end)
    
    it("should use directory-specific context when enabled", function()
      state.setup({ terminal_per_dir = true })
      
      -- ディレクトリ1のターミナル
      local terminal1 = { id = "test1" }
      state.set_terminal(terminal1, "dir_/home/user/project1")
      
      -- ディレクトリ2のターミナル
      local terminal2 = { id = "test2" }
      state.set_terminal(terminal2, "dir_/home/user/project2")
      
      -- それぞれ独立して管理される
      assert.equals(terminal1, state.get_terminal("dir_/home/user/project1"))
      assert.equals(terminal2, state.get_terminal("dir_/home/user/project2"))
    end)
  end)
  
  describe("cleanup", function()
    it("should track last used time", function()
      state.setup()
      
      local before_time = vim.loop.now()
      local terminal = { id = "test" }
      state.set_terminal(terminal)
      
      local current_state = state.get_state()
      local last_used = current_state.last_used["global"]
      
      assert.is_not_nil(last_used)
      assert.is_true(last_used >= before_time)
    end)
    
    it("should clean up old terminals", function()
      state.setup({ cleanup_timeout = 100 }) -- 100ms timeout for testing
      
      local old_terminal = {
        id = "old",
        is_open = function() return false end,
        shutdown = function() end,
      }
      
      state.set_terminal(old_terminal, "old_context")
      
      -- 手動で古い時刻を設定（テスト用）
      local current_state = state.get_state()
      current_state.last_used["old_context"] = vim.loop.now() - 200 -- 200ms前
      
      state.cleanup_old_terminals()
      
      assert.is_nil(state.get_terminal("old_context"))
    end)
    
    it("should not clean up open terminals", function()
      state.setup({ cleanup_timeout = 100 })
      
      local open_terminal = {
        id = "open",
        is_open = function() return true end,
      }
      
      state.set_terminal(open_terminal, "open_context")
      
      -- 手動で古い時刻を設定
      local current_state = state.get_state()
      current_state.last_used["open_context"] = vim.loop.now() - 200
      
      state.cleanup_old_terminals()
      
      -- 開いているターミナルは削除されない
      assert.equals(open_terminal, state.get_terminal("open_context"))
    end)
  end)
  
  describe("state management", function()
    it("should get current state", function()
      state.setup()
      
      local terminal = {
        id = "test",
        is_open = function() return true end,
      }
      state.set_terminal(terminal)
      
      local current_state = state.get_state()
      
      assert.is_not_nil(current_state.terminals)
      assert.is_not_nil(current_state.last_used)
      assert.is_not_nil(current_state.config)
      assert.is_true(current_state.terminals["global"].is_open)
      assert.is_true(current_state.terminals["global"].has_instance)
    end)
    
    it("should reset state", function()
      state.setup()
      
      -- いくつかのターミナルを追加
      for i = 1, 3 do
        state.set_terminal({ id = "test" .. i }, "context_" .. i)
      end
      
      state.reset()
      
      local current_state = state.get_state()
      assert.equals(0, vim.tbl_count(current_state.terminals))
      assert.equals(0, vim.tbl_count(current_state.last_used))
    end)
  end)
  
  describe("autocmds", function()
    it("should handle buffer deletion", function()
      state.setup({ terminal_per_buffer = true })
      
      local terminal = {
        id = "test",
        is_open = function() return false end,
        shutdown = function() end,
      }
      
      state.set_terminal(terminal, "buf_123")
      state.on_buf_delete(123)
      
      assert.is_nil(state.get_terminal("buf_123"))
    end)
    
    it("should not affect terminals when buffer mode is disabled", function()
      state.setup({ terminal_per_buffer = false })
      
      local terminal = { id = "test" }
      state.set_terminal(terminal)
      
      state.on_buf_delete(123)
      
      -- グローバルターミナルは影響を受けない
      assert.equals(terminal, state.get_terminal())
    end)
  end)
end)