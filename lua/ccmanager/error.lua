local M = {}

-- エラーレベル定義
M.levels = {
  ERROR = vim.log.levels.ERROR,
  WARN = vim.log.levels.WARN,
  INFO = vim.log.levels.INFO,
  DEBUG = vim.log.levels.DEBUG,
}

-- ログ機能の有効/無効を管理
M.debug_enabled = false

-- ログを出力
function M.log(level, message, context)
  if level == M.levels.DEBUG and not M.debug_enabled then
    return
  end

  local prefix = "[CCManager] "
  if context then
    prefix = prefix .. "[" .. context .. "] "
  end

  vim.notify(prefix .. message, level)
end

-- エラーメッセージを通知
function M.error(message, context)
  M.log(M.levels.ERROR, message, context)
end

-- 警告メッセージを通知
function M.warn(message, context)
  M.log(M.levels.WARN, message, context)
end

-- 情報メッセージを通知
function M.info(message, context)
  M.log(M.levels.INFO, message, context)
end

-- デバッグメッセージを通知
function M.debug(message, context)
  M.log(M.levels.DEBUG, message, context)
end

-- 安全にコマンドを実行
function M.safe_execute(cmd, error_msg, context)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    M.error(error_msg or ("Failed to execute command: " .. cmd), context)
    return nil, "Failed to execute command"
  end

  local result = handle:read("*a")
  local success, exit_type, code = handle:close()
  
  if not success or code ~= 0 then
    local err_msg = string.format("Command failed: %s (exit code: %s)", cmd, tostring(code or "unknown"))
    M.error(error_msg or err_msg, context)
    return nil, err_msg
  end

  return result
end

-- リトライ機能付き関数実行
function M.retry(fn, options)
  options = options or {}
  local max_attempts = options.max_attempts or 3
  local delay = options.delay or 100 -- ミリ秒
  local context = options.context
  local error_msg = options.error_msg

  for attempt = 1, max_attempts do
    local ok, result = pcall(fn)
    if ok then
      return result
    end

    if attempt < max_attempts then
      M.debug(string.format("Attempt %d failed, retrying in %dms: %s", attempt, delay, tostring(result)), context)
      vim.wait(delay)
      delay = delay * 2 -- 指数バックオフ
    else
      M.error(error_msg or string.format("Failed after %d attempts: %s", max_attempts, tostring(result)), context)
      return nil, result
    end
  end
end

-- 安全にモジュールを要求
function M.safe_require(module_name, error_msg, context)
  local ok, module = pcall(require, module_name)
  if not ok then
    M.error(error_msg or string.format("Failed to load module: %s", module_name), context)
    return nil, module
  end
  return module
end

-- 安全にAPIを呼び出す
function M.safe_api_call(fn, error_msg, context)
  local ok, result = pcall(fn)
  if not ok then
    M.error(error_msg or string.format("API call failed: %s", tostring(result)), context)
    return nil, result
  end
  return result
end

-- デバッグモードの切り替え
function M.set_debug(enabled)
  M.debug_enabled = enabled
  if enabled then
    M.info("Debug mode enabled", "Error")
  end
end

return M