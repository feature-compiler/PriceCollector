local users = require('users')
local prices = require('prices')
local json = require('json')
local test_data = require('data')
local smsc = require("smsc")

box.cfg{listen=3301}

users:start()
prices:start()


-- API methods

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

    local accepted, result = pcall(function () users:decode_token(data.token) end)
    if accepted then
        result = prices:get_shops()
    end

    return {
        accepted = accepted,
        result = result
    }
end

function otp_request(request, data)
    local result = users:set_otp(data.phone)
    return {
        result = result
    }
end

function otp_check(request, data)
    local result = users:check_otp(data.phone, data.password)
    return {
        result = result
    }
end

function goods_info(request, token, barcode, shop_uuid)
    return {
        result=nil
    }
end

function send_goods(request, data)
    local status, result = pcall(function () users:decode_token(data.token) end)

    if status then
        for _, good in pairs(data.goods) do
            prices:add_price(good)
        end
    end
    return {
        result=nil
    }
end

function create_goods(request, data)
    local status, result = pcall(function () users:decode_token(data.token) end)

    if status then
        for _, good in pairs(data.goods) do
            local product_data = {name=good.name, uuid=good.uuid}
            local barcodes = good.barcodes
            prices:add_good(barcodes, product_data)
        end
    end

 
    return {
        status=status,
        result=result,
    }
end

function create_shops(request, data)

    
    local status, result = pcall(function () users:decode_token(data.token) end)

    if status then
        for _, shop in pairs(data.shops) do
            result = prices:add_shop(shop)
        end
    end

    return {
        status=status,
        result=result
    }
end

function create_users(request, data)
    local result
    for _, user in pairs(data.users) do
        result = users:add_user(user)
    end
    return {
        result=result
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

function get_all(request, data)

    return {
        users=users:get_users(),
        shops=prices:get_shops(),
        products=prices:get_products(),
        goods=prices:get_goods(),
        barcodes=prices:get_barcodes(),
        tokens=users:get_tokens(),
    }
end


-- local phone = "89156389216"
-- local message = "test message"
-- local response = smsc.send_message(phone, message)
-- print(response.status)