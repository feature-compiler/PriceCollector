M  = {}

--local barcodes_and_prod_name = {}
local goods = {}
local shops = {}
local users = {}
local prices = {}


-- users
local user_1 = {username= "admin", phone="89107138699"}
users.user_1 = user_1

--shops
local shop_1 = {uuid="250", name="Пятерочка, Оруженйный 41"}
shops.shop_1 = shop_1

-- goods
local good_1 = {barcodes={"54491472", "54491473", "23123"},  uuid="123456", name="Coca Cola 0.5",}
goods.good_1 = good_1

--price_record
local price_1 = {price=90.75, barcode="54491472", datetime="2012-04-23T18:25:43.511Z", uuid="250"}
prices.price_1 = price_1

M.users = users
M.shops = shops
M.goods = goods
M.prices = prices

return M