return {
  -- If LazyVim is using blink.cmp (default in newer versions)
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          auto_show = false, -- Stop member functions/LSP popup from showing automatically
        },
      },
    },
  },

  -- Fallback if using nvim-cmp
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      opts.completion = {
        autocomplete = false,
      }
    end,
  },
}
