---@class RFC
local RFC = {}
RFC.__index = RFC

---@return RFC
function RFC:new()
  return setmetatable({}, self)
end

-- @return nil
function RFC:setup()
  vim.api.nvim_create_user_command("RFC", function() end, {})
end

return RFC:new()
