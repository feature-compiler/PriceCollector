local users = require('users')
local prices = require('prices')
local json = require('json')
local test_data = require('data')


box.cfg{listen=3301}

users:start()
prices:start()

-- API methods

function check_token(request, data)
    local accepted, result = pcall(users.decode_token, users, data.token)
    
    if accepted then
        accepted, result = pcall(prices.get_shops, prices)
    end

    return {
        accepted = accepted,
        result = result
    }
end


function otp_request(request, data)
    local accepted, result = pcall(users.set_otp. users, data.phone)
    
    return {
        accepted = accepted,
        result = result
    }
end


function otp_check(request, data)
    local accepted, result = pcall(users.check_otp, users, data.phone, data.password)
    
    return {
        accepted = accepted,
        result = result
    }
end


function goods_info(request, token, barcode, shop_uuid)
    
    return {
        result=nil
    }
end


function send_goods(request, data)
    local accepted, result = pcall(users.decode_token, users, data.token)

    if accepted then
        for _, good in pairs(data.goods) do
            prices:add_price(good)
        end
    end

    return {
        accepted = accepted,
        result = result
    }
end


function create_goods(request, data)
    local accepted, result = pcall(users.decode_token, users, data.token)

    if accepted then
        for _, good in pairs(data.goods) do
            local product_data = {name=good.name, uuid=good.uuid}
            local barcodes = good.barcodes
            accepted, result = pcall(prices.add_good, prices, barcodes, product_data)
        end
    end

    return {
        accepted=accepted,
        result=result,
    }
end


function create_shops(request, data)
    local accepted, result = pcall(users.decode_token, users, data.token)
    
    if accepted then
        for _, shop in pairs(data.shops) do
            accepted, result = pcall(prices.add_shop, prices, shop)
        end
    end

    return {
        accepted=accepted,
        result=result
    }
end


function create_users(request, data)
    local accepted, result
    
    for _, user in pairs(data.users) do
        accepted, result = pcall(users.add_user, users, user)
    
    end
    
    return {
        accepted=accepted,
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