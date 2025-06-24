-- Minimal init for tests
vim.cmd [[set runtimepath=$VIMRUNTIME]]
vim.cmd [[set packpath=/tmp/nvim/site]]

local package_root = '/tmp/nvim/site/pack'
local install_path = package_root .. '/packer/start/plenary.nvim'

-- plenary.nvimのインストール
if vim.fn.isdirectory(install_path) == 0 then
  vim.fn.system { 'git', 'clone', '--depth=1', 'https://github.com/nvim-lua/plenary.nvim', install_path }
end

vim.cmd [[packloadall]]

-- プラグインのパスを追加
local plugin_root = vim.fn.fnamemodify(vim.fn.expand('<sfile>'), ':p:h:h')
vim.opt.rtp:prepend(plugin_root)

-- プラグインのluaディレクトリをパスに追加
package.path = plugin_root .. '/lua/?.lua;' .. package.path
package.path = plugin_root .. '/lua/?/init.lua;' .. package.path

-- toggleterm.nvimのモックを設定
package.loaded["toggleterm"] = nil
package.loaded["toggleterm.terminal"] = nil

-- 基本的なモック関数
_G.create_mock = function()
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