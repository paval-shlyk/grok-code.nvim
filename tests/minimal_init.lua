-- Minimal init for testing grok-code.nvim in headless Neovim / CI
-- This file is used both for smoke tests and with plenary.nvim

-- Make sure we can find the plugin
vim.opt.rtp:prepend(vim.fn.getcwd())

-- Try to find plenary.nvim (used for structured tests)
local plenary_path = vim.fn.stdpath("data") .. "/site/pack/ci/start/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
  plenary_path = "/tmp/plenary.nvim"
  if vim.fn.isdirectory(plenary_path) == 0 then
    vim.fn.system({
      "git",
      "clone",
      "--depth",
      "1",
      "https://github.com/nvim-lua/plenary.nvim",
      plenary_path,
    })
  end
end

vim.opt.rtp:append(plenary_path)

-- Silence noisy notifications during tests
vim.notify = function() end

-- Load plenary test helpers when available
pcall(function()
  vim.cmd("runtime plugin/plenary.vim")
end)
