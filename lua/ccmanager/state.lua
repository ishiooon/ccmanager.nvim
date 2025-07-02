local M = {}

-- ターミナルインスタンスを管理するテーブル
-- key: コンテキストID（バッファ番号またはディレクトリパス）
-- value: ターミナルインスタンス
local terminals = {}

-- ターミナルの最終使用時刻を記録
local last_used = {}

-- 設定を保存
local config = {}

-- タイムアウト時間（ミリ秒）
local CLEANUP_TIMEOUT = 30 * 60 * 1000 -- 30分

-- デバッグ用のログ関数
local function log(msg)
  if config.debug then
    vim.notify("[CCManager State] " .. msg, vim.log.levels.DEBUG)
  end
end

-- コンテキストIDを生成
local function get_context_id(opts)
  opts = opts or {}
  
  if config.terminal_per_buffer then
    -- バッファごとにターミナルを管理
    return "buf_" .. vim.api.nvim_get_current_buf()
  elseif config.terminal_per_dir then
    -- ディレクトリごとにターミナルを管理
    return "dir_" .. vim.fn.getcwd()
  else
    -- グローバルで単一のターミナル
    return "global"
  end
end

-- ターミナルインスタンスを取得
function M.get_terminal(context_id)
  context_id = context_id or get_context_id()
  local terminal = terminals[context_id]
  
  if terminal then
    last_used[context_id] = vim.loop.now()
    log("Retrieved terminal for context: " .. context_id)
  end
  
  return terminal
end

-- ターミナルインスタンスを設定
function M.set_terminal(terminal, context_id)
  context_id = context_id or get_context_id()
  terminals[context_id] = terminal
  last_used[context_id] = vim.loop.now()
  log("Set terminal for context: " .. context_id)
  
  -- 自動クリーンアップを開始
  M.start_cleanup_timer()
end

-- ターミナルインスタンスを破棄
function M.destroy_terminal(context_id)
  context_id = context_id or get_context_id()
  local terminal = terminals[context_id]
  
  if terminal then
    -- ターミナルが開いている場合は閉じる
    if terminal.is_open and terminal:is_open() then
      terminal:close()
    end
    
    -- シャットダウン処理
    if terminal.shutdown then
      terminal:shutdown()
    end
    
    terminals[context_id] = nil
    last_used[context_id] = nil
    log("Destroyed terminal for context: " .. context_id)
  end
end

-- すべてのターミナルを破棄
function M.destroy_all_terminals()
  log("Destroying all terminals")
  for context_id, _ in pairs(terminals) do
    M.destroy_terminal(context_id)
  end
end

-- 古いターミナルをクリーンアップ
function M.cleanup_old_terminals()
  local now = vim.loop.now()
  local cleaned = 0
  
  for context_id, timestamp in pairs(last_used) do
    if now - timestamp > CLEANUP_TIMEOUT then
      local terminal = terminals[context_id]
      -- 開いていないターミナルのみクリーンアップ
      if terminal and (not terminal.is_open or not terminal:is_open()) then
        M.destroy_terminal(context_id)
        cleaned = cleaned + 1
      end
    end
  end
  
  if cleaned > 0 then
    log("Cleaned up " .. cleaned .. " old terminals")
  end
end

-- クリーンアップタイマー
local cleanup_timer = nil

-- クリーンアップタイマーを開始
function M.start_cleanup_timer()
  if cleanup_timer then
    return -- すでに動作中
  end
  
  cleanup_timer = vim.loop.new_timer()
  cleanup_timer:start(CLEANUP_TIMEOUT, CLEANUP_TIMEOUT, vim.schedule_wrap(function()
    M.cleanup_old_terminals()
  end))
  
  log("Started cleanup timer")
end

-- クリーンアップタイマーを停止
function M.stop_cleanup_timer()
  if cleanup_timer then
    cleanup_timer:stop()
    cleanup_timer:close()
    cleanup_timer = nil
    log("Stopped cleanup timer")
  end
end

-- バッファが削除されたときの処理
function M.on_buf_delete(bufnr)
  if config.terminal_per_buffer then
    local context_id = "buf_" .. bufnr
    M.destroy_terminal(context_id)
  end
end

-- 自動コマンドの設定
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("CCManagerState", { clear = true })
  
  -- バッファ削除時のクリーンアップ
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(args)
      M.on_buf_delete(args.buf)
    end,
  })
  
  -- Neovim終了時のクリーンアップ
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.stop_cleanup_timer()
      M.destroy_all_terminals()
    end,
  })
  
  log("Set up autocmds")
end

-- セットアップ
function M.setup(opts)
  config = opts or {}
  
  -- デフォルト設定
  config.terminal_per_buffer = config.terminal_per_buffer or false
  config.terminal_per_dir = config.terminal_per_dir or false
  config.cleanup_timeout = config.cleanup_timeout or CLEANUP_TIMEOUT
  config.debug = config.debug or false
  
  -- タイムアウトを更新
  CLEANUP_TIMEOUT = config.cleanup_timeout
  
  -- 自動コマンドの設定
  M.setup_autocmds()
  
  log("State management initialized")
end

-- 現在の状態を取得（デバッグ用）
function M.get_state()
  local state = {
    terminals = {},
    last_used = last_used,
    config = config,
  }
  
  for context_id, terminal in pairs(terminals) do
    state.terminals[context_id] = {
      is_open = terminal.is_open and terminal:is_open() or false,
      has_instance = terminal ~= nil,
    }
  end
  
  return state
end

-- 状態をリセット
function M.reset()
  M.stop_cleanup_timer()
  M.destroy_all_terminals()
  terminals = {}
  last_used = {}
  log("State reset")
end

return M