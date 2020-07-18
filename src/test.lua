local User = {}
local M = {}

function User:new()                         
  local newObj = {id = 1,
            username = 'JohnDoe',
            phone = '+791111xxx',
            is_super = false,
            salt = 'salt',
            shadow = 'shadow',}

  self.__index = self                      
  return setmetatable(newObj, self)       
end

admin = User:new()
admin.is_super = true
admin.username = 'root'

user = User:new()
user.id = 2

M.user = user
M.admin = admin

return M

