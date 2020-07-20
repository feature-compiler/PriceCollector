local utils = require("utils")

local user

for k, v in pairs(utils.read_json("users")) do
  user = v
end

print(user.username)

