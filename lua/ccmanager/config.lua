local M = {}

-- デフォルト設定
M.defaults = {
  keymap = "<leader>cm",
  window = {
    size = 0.3,
    position = "right",
  },
  command = "npx ccmanager",
  terminal_keymaps = {
    normal_mode = "<C-q>",
    window_nav = "<C-w>",
    paste = "<C-S-v>",
  },
  wsl_optimization = {
    enabled = true,
    check_clipboard = true,
    fix_paste = true,
  },
}

-- バリデーションルール
local validators = {}

-- window.sizeのバリデーション
validators.window_size = function(value)
  if type(value) ~= "number" then
    return false, "window.size must be a number"
  end
  if value < 0 or value > 1 then
    return false, "window.size must be between 0 and 1"
  end
  return true
end

-- window.positionのバリデーション
validators.window_position = function(value)
  local valid_positions = {
    right = true,
    left = true,
    float = true,
    bottom = true,
    top = true,
    vertical = true,
    horizontal = true,
  }
  if type(value) ~= "string" then
    return false, "window.position must be a string"
  end
  if not valid_positions[value] then
    local valid_list = vim.tbl_keys(valid_positions)
    table.sort(valid_list)
    return false, string.format("window.position must be one of: %s", table.concat(valid_list, ", "))
  end
  return true
end

-- commandのバリデーション
validators.command = function(value)
  if type(value) ~= "string" then
    return false, "command must be a string"
  end
  if value == "" then
    return false, "command cannot be empty"
  end
  return true
end

-- keymapのバリデーション
validators.keymap = function(value)
  if type(value) ~= "string" then
    return false, "keymap must be a string"
  end
  if value == "" then
    return false, "keymap cannot be empty"
  end
  -- 基本的なキーマップパターンをチェック
  -- <leader>、<C-x>、\cm、<F5>などの一般的なパターンを許可
  if not (value:match("^<.+>") or value:match("^\\%w+") or value:match("^[%w%-]+$")) then
    return false, "keymap appears to be invalid"
  end
  return true
end

-- terminal_keymapsのバリデーション
validators.terminal_keymaps = function(value)
  if type(value) ~= "table" then
    return false, "terminal_keymaps must be a table"
  end
  
  -- 各キーマップをチェック
  for key, keymap in pairs(value) do
    if type(keymap) ~= "string" then
      return false, string.format("terminal_keymaps.%s must be a string", key)
    end
  end
  
  return true
end

-- wsl_optimizationのバリデーション
validators.wsl_optimization = function(value)
  if type(value) ~= "table" then
    return false, "wsl_optimization must be a table"
  end
  
  -- 各設定をチェック
  if value.enabled ~= nil and type(value.enabled) ~= "boolean" then
    return false, "wsl_optimization.enabled must be a boolean"
  end
  if value.check_clipboard ~= nil and type(value.check_clipboard) ~= "boolean" then
    return false, "wsl_optimization.check_clipboard must be a boolean"
  end
  if value.fix_paste ~= nil and type(value.fix_paste) ~= "boolean" then
    return false, "wsl_optimization.fix_paste must be a boolean"
  end
  
  return true
end

-- バリデーション実行
local function validate_field(field_path, value, validator)
  local ok, err = validator(value)
  if not ok then
    vim.notify(string.format("CCManager: Invalid config - %s", err), vim.log.levels.WARN)
    return false
  end
  return true
end

-- 設定のバリデーションと正規化
function M.validate(config)
  config = config or {}
  local validated = vim.deepcopy(config)
  local has_errors = false
  
  -- window設定のバリデーション
  if validated.window then
    if validated.window.size ~= nil then
      if not validate_field("window.size", validated.window.size, validators.window_size) then
        validated.window.size = M.defaults.window.size
        has_errors = true
      end
    end
    
    if validated.window.position ~= nil then
      if not validate_field("window.position", validated.window.position, validators.window_position) then
        validated.window.position = M.defaults.window.position
        has_errors = true
      end
    end
  end
  
  -- commandのバリデーション
  if validated.command ~= nil then
    if not validate_field("command", validated.command, validators.command) then
      validated.command = M.defaults.command
      has_errors = true
    end
  end
  
  -- keymapのバリデーション
  if validated.keymap ~= nil then
    if not validate_field("keymap", validated.keymap, validators.keymap) then
      validated.keymap = M.defaults.keymap
      has_errors = true
    end
  end
  
  -- terminal_keymapsのバリデーション
  if validated.terminal_keymaps ~= nil then
    if not validate_field("terminal_keymaps", validated.terminal_keymaps, validators.terminal_keymaps) then
      validated.terminal_keymaps = M.defaults.terminal_keymaps
      has_errors = true
    end
  end
  
  -- wsl_optimizationのバリデーション
  if validated.wsl_optimization ~= nil then
    if not validate_field("wsl_optimization", validated.wsl_optimization, validators.wsl_optimization) then
      validated.wsl_optimization = M.defaults.wsl_optimization
      has_errors = true
    end
  end
  
  if has_errors then
    vim.notify("CCManager: Some invalid settings were replaced with defaults", vim.log.levels.INFO)
  end
  
  return validated
end

-- デフォルト設定とマージ
function M.merge_with_defaults(config)
  local validated = M.validate(config)
  return vim.tbl_deep_extend("force", M.defaults, validated)
end

-- 設定のサマリーを表示
function M.show_config(config)
  local lines = {
    "CCManager Configuration:",
    "========================",
    string.format("Keymap: %s", config.keymap),
    string.format("Command: %s", config.command),
    "",
    "Window:",
    string.format("  Size: %.1f%%", config.window.size * 100),
    string.format("  Position: %s", config.window.position),
    "",
    "Terminal Keymaps:",
    string.format("  Normal mode: %s", config.terminal_keymaps.normal_mode or "not set"),
    string.format("  Window nav: %s", config.terminal_keymaps.window_nav or "not set"),
    string.format("  Paste: %s", config.terminal_keymaps.paste or "not set"),
    "",
    "WSL2 Optimization:",
    string.format("  Enabled: %s", tostring(config.wsl_optimization.enabled)),
    string.format("  Check clipboard: %s", tostring(config.wsl_optimization.check_clipboard)),
    string.format("  Fix paste: %s", tostring(config.wsl_optimization.fix_paste)),
  }
  
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M