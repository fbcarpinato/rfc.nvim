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

  vim.api.nvim_create_user_command("RFC", function() end, {})
end

return setmetatable({
  setup = function(opts)
    local rfc_instance = RFC:new()
    rfc_instance:setup(opts)
  end,
}, RFC)
