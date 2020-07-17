local users = require('users')
local prices = require('prices')
local test_data = require('test')

box.cfg{listen=3301}

users:start()
prices:start()


-- API methods

function check_token(request, username, token)
    return {
        result=nil
    }
end

function otp_request(request, phone)
    return {
        result=nil
    }
end

function otp_check(request, phone, token)
    return {
        result=nil
    }
end

function goods_info(request, token, barcode, shop_uuid)
    return {
        result=nil
    }
end

function send_goods(request, token, goods)
    return {
        result=nil
    }
end

function create_goods(request, token, goods)
    return {
        result=nil
    }
end

function create_shops(request, token, goods)
    return {
        result=nil
    }
end

function create_users(request, token, users)
    return {
        result=nil
    }
end

function get_price_history(request, token)
    return {
        result=nil
    }
end

function accept_price_history(request, price_history)
    return {
        result=nil
    }
end

-- test
local admin = test_data.admin
local simple_user = test_data.user

users:add_user(admin)
users:add_user(simple_user)

-- print(users:get_user(1))
-- print(users:get_user(2))
local new_token = 'serious_strong_pass'
users:add_token(admin.id, new_token)
print(users:check_token(admin.username, new_token))

