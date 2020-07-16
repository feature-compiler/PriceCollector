local users = require('users')
local prices = require('prices')

box.cfg{}

users:start()
prices:start()

-- users:add_user({
--     username="admin",
--     phone="+78800555535",
--     id=1,
--     is_super=true

-- })

-- users:add_user({
--     username="not_admin",
--     phone="---------",
--     id=2,
--     is_super=false

-- })


-- print(users:get_user(1))
-- print(users:get_user(2))