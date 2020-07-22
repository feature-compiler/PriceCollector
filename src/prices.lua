local avro = require('avro_schema')
local schema = require("schemes")
local log = require("log")
local utils = require("utils")

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

    products:create_index('secondary', {
        type = "tree",
        parts = {'uuid'},
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

    shops:create_index('secondary', {
        type = "tree",
        parts = {'uuid'},
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

    barcodes:create_index('secondary', {
        type = "tree",
        parts = {'barcode'},
        unique = true,
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
            return false
        end
        box.space.shops:replace(tuple)
        return true
    end,



    add_product = function (self, product)
        -- product [ uuid: , name: ] (uuid is unique)
        print(product)
        product.id = box.sequence.products_id:next()

        local ok, tuple = self.product_model.flatten(product)

        if not ok then
            return false
        end

        box.space.products:replace(tuple)
        return product
    end,

     add_barcode = function (self, barcode)
        -- barcode [product_id, barcode_value] last is unique
        local ok, tuple = self.barcode_model.flatten(barcode)

        if not ok then
            return false
        end
        box.space.barcodes:replace(tuple)
        return barcode
    end,

    add_good = function (self, barcodes, product)

        --check existing product with same uuid
        local product_exist = box.space.products.index.secondary:get(product.uuid)
        if product_exist == nil then
            product = self.add_product(self, product)
        else
            product = product_exist
        end

        -- barcodes is {'123', '345', '567'}
        for _, barcode_value in pairs(barcodes) do
            --check existing barcode with same barcode value
            local barcode = {product_id=product.id, barcode=barcode_value}
            local barcode_exist = box.space.barcodes.index.secondary:get(barcode_value)

            if barcode_exist == nil then
                --create barcode
                barcode = self.add_barcode(self, barcode)
            end
        end
    end,

    get_shops = function(self)
        return utils.tables_to_table(box.space.shops)
    end,

    get_products = function(self)
        return utils.tables_to_table(box.space.products)
    end,

    get_barcodes = function(self)
        return utils.tables_to_table(box.space.barcodes)
    end,

    get_goods = function(self)
        local goods_ =  {}
        for key, price in box.space.prices:pairs() do
            local price_ = utils.tuple_to_table(box.space.shops:format(), price)
            if price_.approved == true then
                --append price_ to goods
            end
            table.insert(goods_, price_)
        end
        return goods_
    end,

}

return app