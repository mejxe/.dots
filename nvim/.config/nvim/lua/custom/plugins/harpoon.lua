-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			-- REQUIRED
			local harpoon = require("harpoon")
			harpoon:setup()
			-- REQUIRED

			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "Add to harpoon" })
			vim.keymap.set("n", "<leader>o", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon menu" })

			vim.keymap.set("n", "<M-h>", function()
				harpoon:list():select(1)
			end)
			vim.keymap.set("n", "<M-j>", function()
				harpoon:list():select(2)
			end)
			vim.keymap.set("n", "<M-k>", function()
				harpoon:list():select(3)
			end)
			vim.keymap.set("n", "<M-l>", function()
				harpoon:list():select(4)
			end)

			-- Toggle previous & next buffers stored within Harpoon list
			vim.keymap.set("n", "<C-S-P>", function()
				harpoon:list():prev()
			end)
			vim.keymap.set("n", "<C-S-N>", function()
				harpoon:list():next()
			end)
		end,
	},
}
