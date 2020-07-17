local User = {}
local M = {}

function User:new()                         
  newObj = {id = 1,
            username = 'JohnDoe',
            phone = '+79111xxxx',
            is_super = false}

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
