local M = {
}

M.config = {
  mappings = {
  },
}

local function go_to_next(char)
  local rx_char = char
  if char == '[' or char == ']' then
    rx_char = '\\' .. char
  end


  local initial_line = vim.fn.line('.') or 1
  local initial_col = vim.fn.col('.') or 1

  local function restore_cursor()
    vim.fn.cursor({ initial_line, initial_col })
  end

  local pos = vim.fn.search(rx_char, 'Wn')

  if pos == nil or pos == 0 then
    return {
      success = false,
    }
  end

  local char_under_cursor = vim.fn.getline('.'):sub(initial_col, initial_col)

  if char_under_cursor == char then
    vim.fn.search('\\S', 'W')
  end

  local search = '[{}\\[\\]()' .. rx_char .. ']'

  vim.fn.search(search, 'Wc')

  local col = vim.fn.col('.')
  local line = vim.fn.line('.')

  if col == nil or col == 0 or line == nil or line == 0 then
    restore_cursor()
    return {
      success = false,
    }
  end

  local character = vim.fn.getline('.'):sub(col, col)

  local opening_bracket_in_jump = false
  while character ~= char do
    if character == '{' or character == '[' or character == '(' then
      -- jumping over the braces
      if character == '{' then
        vim.fn.searchpair('{', '', '}')
      elseif character == '[' then
        vim.fn.searchpair('\\[', '', '\\]')
      elseif character == '(' then
        vim.fn.searchpair('(', '', ')')
      end
      opening_bracket_in_jump = true
    else
      pos = vim.fn.search(search, 'W')
      if pos == nil or pos == 0 then
        restore_cursor()
        return {
          success = false,
        }
      end
      opening_bracket_in_jump = false
    end

    col = vim.fn.col('.')
    line = vim.fn.line('.')

    if col == nil or col == 0 or line == nil or line == 0 then
      restore_cursor()
      return {
        success = false,
      }
    end

    character = vim.fn.getline('.'):sub(col, col)
  end

  return {
    success = true,
    opening_bracket_in_jump = opening_bracket_in_jump,
  }
end

function M.until_coma(char)
  local col_nr = vim.fn.col('.')
  local current_line = vim.fn.getline('.')
  local char_before_cursor = current_line:sub(col_nr - 1, col_nr - 1)

  local res = go_to_next(char)

  if res.success then
    -- Success!

    -- If the char before the cursor was a non-alphanumeric character, we go
    if char_before_cursor == nil or char_before_cursor == '' or char_before_cursor:match('%W') then
      vim.fn.search('\\S', 'W')
    end
  end
end

function M.until_bracket(bracket_char)
  local res = go_to_next(bracket_char)

  if res.success and res.opening_bracket_in_jump then
    -- The opening bracket was in the jumped area, so we go past it
    vim.fn.search('\\S', 'W')
  end
end

function M.simple_until(char)
  go_to_next(char)
end

function M.setup_mappings()
  local opts = { noremap = true }

  vim.api.nvim_set_keymap("o", ',', "<Cmd>lua require('until').until_coma(',')<CR>", opts)
  vim.api.nvim_set_keymap("o", '.', "<Cmd>lua require('until').until_coma('.')<CR>", opts)
  vim.api.nvim_set_keymap("o", ']', "<Cmd>lua require('until').until_bracket(']')<CR>", opts)
  vim.api.nvim_set_keymap("o", '}', "<Cmd>lua require('until').until_bracket('}')<CR>", opts)
  vim.api.nvim_set_keymap("o", ')', "<Cmd>lua require('until').until_bracket(')')<CR>", opts)
  vim.api.nvim_set_keymap("o", '(', "<Cmd>lua require('until').simple_until('(')<CR>", opts)
  vim.api.nvim_set_keymap("o", '[', "<Cmd>lua require('until').simple_until('[')<CR>", opts)
  vim.api.nvim_set_keymap("o", '{', "<Cmd>lua require('until').simple_until('{')<CR>", opts)
  vim.api.nvim_set_keymap("o", '"', "<Cmd>lua require('until').simple_until('\"')<CR>", opts)
  vim.api.nvim_set_keymap("o", "'", "<Cmd>lua require('until').simple_until(\"'\")<CR>", opts)
end

function M.setup(user_opts)
  M.config = vim.tbl_extend("force", M.config, user_opts or {})

  M.setup_mappings()
end

return M
