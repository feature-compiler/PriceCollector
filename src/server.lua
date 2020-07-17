local users = require('users')
local prices = require('prices')

box.cfg{listen=3301}

users:start()
prices:start()


-- API

function add_user(request, user)
    return {
        result=users:add_user(user),
        new_user=users:get_user(user.id)

    }
end

-- users:add_user({
--     username="admin",
--     phone="+78800555535",
--     id=1,
--     is_super=true

-- })