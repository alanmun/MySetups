vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 8
vim.opt.termguicolors = true

local function map(mode, lhs, rhs, opts)
	opts = opts or {}

	if vim.keymap and vim.keymap.set then
		vim.keymap.set(mode, lhs, rhs, opts)
		return
	end

	-- Neovim 0.6 does not have vim.keymap.set.
	local legacy_opts = {}
	for key, value in pairs(opts) do
		legacy_opts[key] = value
	end
	if legacy_opts.remap ~= nil then
		legacy_opts.noremap = not legacy_opts.remap
		legacy_opts.remap = nil
	elseif legacy_opts.noremap == nil then
		legacy_opts.noremap = true
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, legacy_opts)
end

-- Exit insert mode quickly with jj
map('i', 'jj', '<Esc>')

-- Keep multi-key mapping timeout short so jj must be fast
vim.opt.timeoutlen = 300

-- VSCode-like move line/selection mappings
map('n', '<A-Down>', ':m+1<CR>==')
map('n', '<A-Up>', ':m-2<CR>==')
map('n', '<A-j>', ':m+1<CR>==')
map('n', '<A-k>', ':m-2<CR>==')

map('x', '<A-Down>', ":m '>+1<CR>gv=gv")
map('x', '<A-Up>', ":m '<-2<CR>gv=gv")
map('x', '<A-j>', ":m '>+1<CR>gv=gv")
map('x', '<A-k>', ":m '<-2<CR>gv=gv")
