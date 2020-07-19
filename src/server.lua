local users = require('users')
local prices = require('prices')
local test_data = require('test')
local auth = require('auth')

box.cfg{listen=3301}

users:start()
prices:start()


-- API methods

local STATUS = 200
local HEADERS = {["X-Tarantool"] = "FROM_TNT"}

function add_user(request, data)
    local result = users:add_user(data)
    local body = {result=result}
    return body, HEADERS, STATUS
end

function add_token(request, data)
    local result = users:add_token(data.user_id)
    local body = {result=result}
    return body, HEADERS, STATUS
end

function check_token(request, data)

    local result = users:decode_token(data.token)
    local body = {result=result}

    
    return body, HEADERS, STATUS
end

function otp_request(request, phone)
    local body = {}
    return body, HEADERS, STATUS
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
