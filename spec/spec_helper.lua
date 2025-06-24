-- テストヘルパー設定
-- plenary.nvimのテスト機能をセットアップ

-- プラグインのパスを追加
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:match("@(.*)"), ":p:h:h")
vim.opt.rtp:prepend(plugin_root)

-- toggleterm.nvimのモックを設定
package.loaded["toggleterm"] = nil
package.loaded["toggleterm.terminal"] = nil

-- 基本的なモック関数
local function create_mock()
  return {
    calls = {},
    call = function(self, ...)
      table.insert(self.calls, {...})
    end,
    call_count = function(self)
      return #self.calls
    end,
    reset = function(self)
      self.calls = {}
    end,
  }
end

return {
  create_mock = create_mock,
  plugin_root = plugin_root,
}