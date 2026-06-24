local map = vim.keymap.set

map("n", "<leader>w", "<cmd>wa<cr>", { desc = "Write all" })
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>e", "<cmd>Oil<cr>", { desc = "Explorer" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help" })
map("n", "<leader>td", "<cmd>TodoTelescope<cr>", { desc = "Todo list" })
map("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })

map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>do", vim.diagnostic.open_float, { desc = "Diagnostic float" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostic list" })
