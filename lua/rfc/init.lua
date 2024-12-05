---@class RFC
---@field config table Configuration table for RFC
---@field config.cache_path string
local RFC = {}
RFC.__index = RFC

---Create a new RFC object.
---@return RFC
function RFC:new()
  return setmetatable({
    config = {
      cache_path = "rfc_index.xml", -- Default cache path
    },
  }, self)
end

---Sets up the RFC environment.
---@param opts table Optional configuration to override defaults
---@param opts.cache_path string destination of the file that holds the RFCs index
---@return nil
function RFC:setup(opts)
  -- If opts is provided, merge it with the default config
  if opts then
    for k, v in pairs(opts) do
      self.config[k] = v
    end
  end

  local curl = require("plenary.curl")
  local cache_path = vim.fn.stdpath("cache") .. "/" .. self.config.cache_path

  -- Check if the file exists
  if not vim.loop.fs_stat(cache_path) then
    -- Fetch RFC index from the URL
    local response = curl.get("https://www.rfc-editor.org/in-notes/rfc-index.xml")

    -- Handle HTTP request errors
    if not response.status or response.status ~= 200 or not response.body then
      error("Failed to fetch RFC index. HTTP status: " .. (response.status or "unknown"))
    end

    -- Write the response body to the cache file
    local file = io.open(cache_path, "w")
    if file then
      file:write(response.body)
      file:close()
    else
      error("Failed to open cache file for writing: " .. cache_path)
    end
  end

  -- Create a user command in Neovim
  vim.api.nvim_create_user_command("RFC", function() end, {})
end

-- Now return a table with `setup` as a function.
return setmetatable({
  setup = function(opts)
    -- Call `setup` on a new instance of `RFC` with the provided options
    local rfc_instance = RFC:new()
    rfc_instance:setup(opts)
  end,
}, RFC)
