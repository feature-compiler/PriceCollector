local users = require('users')
local prices = require('prices')
local json = require('json')
local test_data = require('data')


box.cfg{listen=3301}

users:start()
prices:start()

-- API methods

function CheckToken(request, data)
    
    local accepted, result = pcall(users.decode_token, users, data.token)
    
    if accepted then
        accepted, result = pcall(prices.get_shops, prices)
    end

    return {
        accepted = accepted,
        result = result
    }
end


function OTPRequest(request, data)
    
    local accepted, result = pcall(users.set_otp, users, data.phone)
    
    return {
        accepted = accepted,
        result = result
    }
end


function OTPCheck(request, data)
    
    local accepted, result = pcall(users.check_otp, users, data.phone, data.password)
    
    return {
        accepted = accepted,
        result = result
    }
end


function goods_info(request, data)
    
    local accepted, result = pcall(users.decode_token, users, data.token)
    
    if accepted then
        accepted, result = pcall(prices.get_good, prices, data.barcode, data.shopuuid)
    end
    
    return {
        accepted=accepted,
        result=result
    }
end


function SendGoods(request, data)
    
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


function CreateGoods(request, data)
    
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


function CreateShops(request, data)
    
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


function CreateUsers(request, data)
    
    local accepted, result = pcall(users.decode_token, users, data.token)
    
    if accepted then
        for _, user in pairs(data.users) do
            accepted, result = pcall(users.add_user, users, user)
        end
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


function GetAll(request, data)
    --отладочная функция
    return {
        users=users:get_users(),
        shops=prices:get_shops(),
        products=prices:get_products(),
        goods=prices:get_goods(),
        barcodes=prices:get_barcodes(),
        tokens=users:get_tokens(),
    }
end


-- for _, shop in pairs(test_data.shops) do
--     prices:add_shop(shop)
-- end


-- for _, good in pairs(test_data.goods) do
--     local product_data = {name=good.name, uuid=good.uuid}
--     local barcodes = good.barcodes
--     prices:add_good(barcodes, product_data)
-- end


-- for _, price in pairs(test_data.prices) do
--     prices:add_price(price)
-- end
for _, user in pairs(test_data.users) do
    users:add_user(user)
end

users:add_token(1)

print(json.encode(prices:get_shops()))
print(json.encode(prices:get_products()))
print(json.encode(prices:get_goods()))
print(json.encode(prices:get_barcodes()))

