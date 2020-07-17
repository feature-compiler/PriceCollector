local users = require('users')
local prices = require('prices')
local test_data = require('test')

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


local admin = test_data.admin
local simple_user = test_data.user

users:add_user(admin)
users:add_user(simple_user)

-- print(users:get_user(1))
-- print(users:get_user(2))
local new_token = 'serious_strong_pass'
users:add_token(admin.id, new_token)
print(users:check_token(admin.username, new_token))

