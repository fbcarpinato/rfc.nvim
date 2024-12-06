---@class RFC
---@field config table Configuration table for RFC
---@field config.cache_path string
local RFC = {}
RFC.__index = RFC

---@return RFC
function RFC:new()
  return setmetatable({
    config = {
      cache_path = "rfc_index.xml", -- Default cache path
    },
  }, self)
end

---@param opts table Optional configuration to override defaults
---@param opts.cache_path string destination of the file that holds the RFCs index
---@return nil
function RFC:setup(opts)
  if opts then
    for k, v in pairs(opts) do
      self.config[k] = v
    end
  end

  local curl = require("plenary.curl")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local cache_path = vim.fn.stdpath("cache") .. "/" .. self.config.cache_path

  if not vim.loop.fs_stat(cache_path) then
    local response = curl.get("https://www.rfc-editor.org/in-notes/rfc-index.xml")

    if not response.status or response.status ~= 200 or not response.body then
      error("Failed to fetch RFC index. HTTP status: " .. (response.status or "unknown"))
    end

    local file = io.open(cache_path, "w")
    if file then
      file:write(response.body)
      file:close()
    else
      error("Failed to open cache file for writing: " .. cache_path)
    end
  end

  vim.api.nvim_create_user_command("RFC", function()
    local rfcs = {
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "Some RFC Title" },
      { doc_id = "RFC1234", title = "HTTp" },
    }

    pickers
        .new(opts, {
          prompt_title = "RFCs",
          finder = finders.new_table({
            results = rfcs,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.doc_id .. " - " .. entry.title,
                ordinal = entry.doc_id .. " - " .. entry.title,
              }
            end,
          }),
          sorter = conf.file_sorter({}),
          attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
              local selection = action_state.get_selected_entry()

              actions.close(prompt_bufnr)

              vim.api.nvim_command("enew")

              local doc_id = selection.value.doc_id
              local title = selection.value.title

              print(doc_id)
              print(title)

              vim.api.nvim_buf_set_lines(0, 0, -1, false, { doc_id, "", title })

              vim.bo.modifiable = false
              vim.bo.readonly = true
            end)
            return true
          end,
        })
        :find()
  end, {})
end

return setmetatable({
  setup = function(opts)
    local rfc_instance = RFC:new()
    rfc_instance:setup(opts)
  end,
}, RFC)
