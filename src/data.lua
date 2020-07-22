M  = {}

local barcodes_and_prod_name = {}
local prices = {}
local shops = {}
local users = {}


-- users
local user_1 = {username= "admin", is_super= true, phone="+7910xxxx"}
users.user_1 = user_1

--shops
local shop_1 = {uuid="a5bf7d6a-696c-4ed7-9798-04594b88dec6", name="Пятерочка, Оруженйный 41"}
shops.shop_1 = shop_1


M.users = users
M.shops = shops
M.barcodes_and_prod_name = barcodes_and_prod_name
M.prices = prices

return M