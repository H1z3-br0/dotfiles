-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Handy CTF/AD additions
vim.keymap.set("n", "<leader>tw", function()
  vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle wrap" })

vim.keymap.set("n", "<leader>tp", function()
  vim.opt.paste = not vim.opt.paste:get()
end, { desc = "Toggle paste mode" })
