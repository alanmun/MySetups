vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 8
vim.opt.termguicolors = true

-- Exit insert mode quickly with jj
vim.keymap.set('i', 'jj', '<Esc>')

-- Keep multi-key mapping timeout short so jj must be fast
vim.opt.timeoutlen = 300

-- VSCode-like move line/selection mappings
vim.keymap.set('n', '<A-Down>', ':m+1<CR>==')
vim.keymap.set('n', '<A-Up>',   ':m-2<CR>==')
vim.keymap.set('n', '<A-j>',    ':m+1<CR>==')
vim.keymap.set('n', '<A-k>',    ':m-2<CR>==')

vim.keymap.set('x', '<A-Down>', ":m '>+1<CR>gv=gv")
vim.keymap.set('x', '<A-Up>',   ":m '<-2<CR>gv=gv")
vim.keymap.set('x', '<A-j>',    ":m '>+1<CR>gv=gv")
vim.keymap.set('x', '<A-k>',    ":m '<-2<CR>gv=gv")
