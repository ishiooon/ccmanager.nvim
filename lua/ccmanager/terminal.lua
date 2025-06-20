local M = {}
local terminal = nil

function M.setup(config)
  M.config = config
end

function M.toggle()
  local ok, toggleterm = pcall(require, "toggleterm")
  if not ok then
    vim.notify("CCManager: toggleterm.nvim is required", vim.log.levels.ERROR)
    return
  end
  
  if not terminal then
    local Terminal = require("toggleterm.terminal").Terminal
    terminal = Terminal:new({
      cmd = M.config.command,
      dir = vim.fn.getcwd(),
      direction = (M.config.window.position == "right" or M.config.window.position == "left") and "vertical" or M.config.window.position,
      size = function()
        if M.config.window.position == "right" or M.config.window.position == "left" then
          return math.floor(vim.o.columns * M.config.window.size)
        else
          return math.floor(vim.o.lines * M.config.window.size)
        end
      end,
      close_on_exit = true,
      hidden = false,
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = term.bufnr })
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { buffer = term.bufnr })
      end,
    })
  end
  
  terminal:toggle()
end

return M