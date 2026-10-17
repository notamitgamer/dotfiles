-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Sync with System Clipboard
vim.opt.clipboard = "unnamedplus"

-- Ctrl+C: Copy selected text in Visual mode to system clipboard
vim.keymap.set("v", "<C-c>", '"+y', { desc = "Copy selection to clipboard" })

-- Ctrl+V: Paste from system clipboard
vim.keymap.set("n", "<C-v>", '"+P', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard in insert" })

-- Ctrl+Z / Ctrl+Y: Undo & Redo
vim.keymap.set({ "n", "i", "v" }, "<C-z>", "<cmd>undo<cr>", { desc = "Undo" })
vim.keymap.set({ "n", "i", "v" }, "<C-y>", "<cmd>redo<cr>", { desc = "Redo" })

-- Ctrl+A: Select All
vim.keymap.set({ "n", "v" }, "<C-a>", "gg<S-v>G", { desc = "Select All" })
vim.keymap.set("i", "<C-a>", "<Esc>gg<S-v>G", { desc = "Select All" })

-- Open terminal in current file's directory with filename in title & environment
local function open_terminal_with_file_context()
  local file_path = vim.fn.expand("%:p")
  local file_name = vim.fn.expand("%:t")
  local file_dir = vim.fn.expand("%:p:h")

  if file_dir == "" or vim.fn.isdirectory(file_dir) == 0 then
    file_dir = (vim.uv or vim.loop).cwd()
  end

  local display_title = (file_name ~= "") and ("   File: " .. file_name .. " ") or "   Terminal "

  local env = {}
  if file_name ~= "" then
    env.FILE = file_name
    env.FILE_PATH = file_path
  end

  if Snacks and Snacks.terminal then
    Snacks.terminal.toggle(nil, {
      cwd = file_dir,
      win = {
        title = display_title,
      },
      env = env,
    })
  elseif LazyVim and LazyVim.terminal then
    LazyVim.terminal(nil, { cwd = file_dir, env = env })
  else
    vim.cmd("botright split | lcd " .. vim.fn.fnameescape(file_dir) .. " | terminal")
  end
end

vim.keymap.set({ "n", "t" }, "<C-/>", open_terminal_with_file_context, { desc = "Terminal with Current File" })
vim.keymap.set({ "n", "t" }, "<C-_>", open_terminal_with_file_context, { desc = "Terminal with Current File" })
