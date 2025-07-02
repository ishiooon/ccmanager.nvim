local M = {}
local config_module = require("ccmanager.config")

-- デフォルト設定はconfig.luaから取得
M.config = config_module.defaults

function M.setup(opts)
  -- 設定のバリデーションとマージ
  M.config = config_module.merge_with_defaults(opts)
  
  local terminal = require("ccmanager.terminal")
  terminal.setup(M.config)
  
  -- キーマップの設定
  local ok = pcall(vim.keymap.set, "n", M.config.keymap, function()
    terminal.toggle()
  end, { desc = "Toggle CCManager" })
  
  if not ok then
    vim.notify("CCManager: Failed to set keymap. Please check your keymap setting.", vim.log.levels.ERROR)
  end
  
  -- コマンドの登録
  vim.api.nvim_create_user_command("CCManagerShowConfig", function()
    config_module.show_config(M.config)
  end, { desc = "Show CCManager configuration" })
  
  vim.api.nvim_create_user_command("CCManagerValidateConfig", function()
    local validation_result = config_module.validate(M.config)
    if validation_result then
      vim.notify("CCManager: Configuration is valid", vim.log.levels.INFO)
    end
  end, { desc = "Validate CCManager configuration" })
end

return M
