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

---@param opts? table Optional configuration to override defaults
---@param opts.cache_path? string Destination of the file that holds the RFCs index
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
    local xml2lua = require("xml2lua")
    local handler = require("xmlhandler.tree")

    local file = io.open(cache_path, "r")
    if not file then
      error("Failed to open cache file for reading: " .. cache_path)
    end

    local content = file:read("*all")
    file:close()

    local parser = xml2lua.parser(handler)
    pcall(function()
      parser:parse(content)
    end)

    if not handler.root["rfc-index"] then
      error("Failed to parse RFC index. The cache file may be corrupt.")
    end

    pickers
        .new({}, {
          prompt_title = "RFCs",
          finder = finders.new_table({
            results = handler.root["rfc-index"]["rfc-entry"],
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry["doc-id"] .. " - " .. (entry["title"] or "No Title"),
                ordinal = entry["doc-id"] .. " - " .. (entry["title"] or "No Title"),
              }
            end,
          }),
          sorter = conf.file_sorter({}),
          attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
              local selection = action_state.get_selected_entry()

              local response = curl.get(
                "https://www.rfc-editor.org/rfc/" .. string.lower(selection.value["doc-id"]) .. ".txt"
              )

              if not response.status or response.status ~= 200 or not response.body then
                error("Failed to fetch RFC content. HTTP status: " .. (response.status or "unknown"))
              end

              actions.close(prompt_bufnr)

              vim.api.nvim_command("enew")

              local lines = {}
              for line in response.body:gmatch("([^\n]*)\n?") do
                table.insert(lines, line)
              end

              vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
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
    local base_path = debug.getinfo(1, "S").source:match("@(.*[/\\])")
    local deps_path = base_path .. "../../deps/xml2lua"

    package.path = package.path .. ";" .. deps_path .. "/?.lua"
    package.path = package.path .. ";" .. deps_path .. "/?/init.lua"

    local rfc_instance = RFC:new()
    rfc_instance:setup(opts)
  end,
}, RFC)
