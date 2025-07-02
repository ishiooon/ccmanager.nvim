local M = {}

-- WSL2環境かどうかを検出する
function M.is_wsl()
  local ok, uname = pcall(vim.fn.system, "uname -r")
  if not ok then
    -- error_handlerを使わずに直接処理
    vim.notify("[CCManager] [Utils] Failed to detect WSL environment", vim.log.levels.WARN)
    return false
  end
  return string.find(uname, "microsoft") ~= nil or string.find(uname, "WSL") ~= nil
end

-- クリップボード設定が適切かチェック
function M.check_clipboard_config()
  if M.is_wsl() then
    local clipboard = vim.g.clipboard
    if not clipboard or type(clipboard) ~= "table" then
      return false
    end
    -- WSL用のクリップボード設定があるかチェック
    return clipboard.name and (clipboard.name == "WslClipboard" or clipboard.name:match("wsl"))
  end
  return true
end

-- WSL2用のクリップボード設定を提案
function M.suggest_wsl_clipboard_config()
  local config = [[
-- WSL2用のクリップボード設定
vim.g.clipboard = {
  name = 'WslClipboard',
  copy = {
    ['+'] = 'clip.exe',
    ['*'] = 'clip.exe',
  },
  paste = {
    ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}]]
  return config
end

return M