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


local admin = test_data.admin
users:add_user(admin)
print(users:get_user(admin.id))


users:add_token(admin.id)

local token = box.space.tokens:get(test_data.admin.id)

print(users:check_token(token.jwt).user_id)