local avro = require('avro_schema')
local schema = require("schemes")
local log = require("log")

local app_name = 'prices'

local function init_space()

    local if_not_exists = true


    local prices = box.schema.space.create(
        'prices',
        {
            -- формат хранимых кортежей
            format = {
                {'id', 'unsigned'},
                {'price_value', 'string'},
                {'date_created','string'},
                {'approved', 'boolean'},
                {'product_id','unsigned'},
                {'shop_id','unsigned'},
            },

            if_not_exists = if_not_exists,
        }
    )
    box.schema.sequence.create ('prices_id',
    {if_not_exists = if_not_exists})

    prices:create_index('primary', {
        type = "HASH",
        parts = {'id'},
        sequence = 'prices_id',
        unique = true,
        if_not_exists = if_not_exists,
    })

    local products = box.schema.space.create(
        'products',
        {
            -- формат хранимых кортежей
            format = {
                {'id', 'unsigned'},
                {'name','string'},
                {'uuid','string'},
            },

            if_not_exists = if_not_exists,
        }
    )

    box.schema.sequence.create ('products_id',
    {if_not_exists = if_not_exists})

    products:create_index('primary', {
        type = "hash",
        parts = {'id'},
        sequence = 'products_id',
        unique = true,
        if_not_exists = if_not_exists,
    })

    local shops = box.schema.space.create(
        'shops',
        {
            -- формат хранимых кортежей
            format = {
                {'id', 'unsigned'},
                {'name','string'},
                {'uuid','string'},
            },

            if_not_exists = if_not_exists,
        }
    )

    box.schema.sequence.create ('shops_id',
    {if_not_exists = if_not_exists})

    shops:create_index('primary', {
        type = "HASH",
        parts = {'id'},
        sequence = 'shops_id',
        unique = true,
        if_not_exists = if_not_exists,
    })

    local barcodes = box.schema.space.create(
        'barcodes',
        {
            -- формат хранимых кортежей
            format = {
                {'product_id', 'unsigned'},
                {'barcode','string'},
            },

            if_not_exists = if_not_exists,
        }
    )

    barcodes:create_index('primary', {
        type = "hash",
        parts = {'product_id'},
        if_not_exists = if_not_exists,
    })


end

local app = {
    
    price_model = {},
    product_model = {},
    shop_model = {},
    barcode_model = {},

    start = function (self)

        init_space()

        local ok_p, price = avro.create(schema.price)
        local ok_prod, product = avro.create(schema.product)
        local ok_s, shop = avro.create(schema.shop)
        local ok_b, barcode = avro.create(schema.barcode)


        if ok_p and ok_prod and ok_s and ok_b then
            local ok_cp, compiled_price = avro.compile(price)
            local ok_cprod, compiled_product = avro.compile(product)
            local ok_cs, compiled_shop = avro.compile(shop)
            local ok_cb, compiled_barcode = avro.compile(barcode)

            if ok_cp and ok_cprod and ok_cs and ok_cb then
                self.price_model = compiled_price
                self.product_model = compiled_product
                self.shop_model = compiled_shop
                self.barcode_model = compiled_barcode

                log.info(app_name .. ' [STARTED]')
                return true
            else
                log.info("Schema compilation failed")
            end
        else
            log.info("Schema creation failed")
        end
        return false

    end,

    add_shop = function (self, shop)
        shop.id = box.sequence.shops_id:next()
        local ok, tuple = self.shop_model.flatten(shop)

        if not ok then
            print("NOT OK TUPLE")
            return false
        end
        box.space.shops:replace(tuple)
        return true
    end,

    get_shops = function(self)
        local shops_ =  box.space.shops:select()
        print(shops_)
        return shops_
    end,

    print_all_data = function(self)
        print("\nSHOPS: ")
        for k, v in pairs(box.space.shops:select()) do
            print(k, v)
        end
        print("\nPRODUCTS: ")
        for k, v in pairs(box.space.tokens:select()) do
            print(k, v)
        end
    end,


}

return app