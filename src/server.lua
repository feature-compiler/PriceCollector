local users = require('users')
local prices = require('prices')
local utils = require("utils")
local test_data = require('data')

box.cfg{listen=3301}

users:start()
prices:start()


-- API methods

local STATUS = 200
local HEADERS = {["X-Tarantool"] = "FROM_TNT"}

function add_user(request, data)
    local user = users:add_user(data)
    return {
        user = user
    }
end

function add_token(request, data)
    local token = users:add_token(data.user_id)
    return {
       token = token
    }
end

function check_token(request, data)

    local status, result = pcall(function () users:decode_token(data.token) end)
    if status then
        status, result = pcall(function () prices:get_shops() end)
    end

    return {
        status = status,
        result = result
    }
end

function otp_request(request, phone)
    local body = {}
    return body
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

function create_shops(request, data)

    --local status, result = pcall(function () prices:add_shop(data.token) end)

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

function test(request, data)

    users:print_all_data()
    prices:print_all_data()
    return {
        result=users:get_users()
    }
end


for k, user in pairs(test_data.users) do
      users:add_user(user)
end

-- for k, shop in pairs(utils.read_json("shops")) do
--     print(prices:add_shop(shop))
-- end

-- users:print_all_data()
-- prices:print_all_data()

-- print(prices:get_shops())

print(users:get_users())