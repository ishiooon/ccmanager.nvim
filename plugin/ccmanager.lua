if vim.fn.has("nvim-0.11.0") == 0 then
  vim.api.nvim_err_writeln("CCManager requires at least nvim-0.11.0")
  return
end

if vim.g.loaded_ccmanager == 1 then
  return
end
vim.g.loaded_ccmanager = 1