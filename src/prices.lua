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
                {'price_value', 'double'},
                {'date_created','string'},
                {'approved', 'boolean'},
                {'product_id','unsigned'},
                {'shop_id','unsigned'},
            },

            if_not_exists = if_not_exists,
        }
    )

    prices:create_index('primary', {
        type = "hash",
        parts = {'id'},
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

    products:create_index('primary', {
        type = "hash",
        parts = {'id'},
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

    shops:create_index('primary', {
        type = "hash",
        parts = {'id'},
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

    start = function (self)

        init_space()

        local ok_p, price = avro.create(schema.price)

        if ok_p then
            local ok_cp, compiled_price = avro.compile(price)

            if ok_cp then
                self.price_model = compiled_price

                log.info(app_name .. ' [STARTED]')
                return true
            else
                log.info("Schema compilation failed")
            end
        else
            log.info("Schema creation failed")
        end
        return false

    end


}

return app