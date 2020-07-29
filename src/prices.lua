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
                {'price', 'number'},
                {'datetime','string'},
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

    prices:create_index('product', {
        type = "tree",
        parts = {'product_id'},
        unique=false,
        if_not_exists = if_not_exists,
    })

    prices:create_index('is_approved',{
        type = "tree",
        parts = {'approved'},
        unique = false,
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
                {'uuid','string'},
                {'name','string'},     
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
        if_not_exists = if_not_exists,
    })

 
    local barcodes = box.schema.space.create(
        'barcodes',
        {
            -- формат хранимых кортежей
            format = {
                {'id', 'unsigned'},
                {'product_id', 'unsigned'},
                {'barcode','string'},
            },

            if_not_exists = if_not_exists,
        }
    )
    box.schema.sequence.create ('barcodes_id',
    {if_not_exists = if_not_exists})


    barcodes:create_index('primary', {
        type = "hash",
        parts = {'id'},
        sequence = 'barcodes_id',
        unique=true,
        if_not_exists = if_not_exists,
    })

    barcodes:create_index('secondary', {
        type = "tree",
        parts = {'barcode'},
        unique = true,
        if_not_exists = if_not_exists,
    })

    barcodes:create_index('product', {
        type = "tree",
        parts = {'product_id'},
        unique = false,
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
            error("Invalid data")
        end
        box.space.shops:replace(tuple)

        return shop
    end,


    add_product = function (self, product)
        
        product.id = box.sequence.products_id:next()

        local ok, tuple = self.product_model.flatten(product)

        if not ok then
            error("Invalid data")
        end

        box.space.products:replace(tuple)

        return product
    end,


     add_barcode = function (self, barcode)
        barcode.id = box.sequence.barcodes_id:next()
        local ok, tuple = self.barcode_model.flatten(barcode)

        if not ok then
            error("Invalid data")
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


    add_price = function(self, price)

        price.id = box.sequence.prices_id:next()
        
        --функция создания цены
        --берем штрихкод и смотрим есть ли совпадения по карточкам
        local barcode_exist = box.space.barcodes.index.secondary:get(price.barcode)
        local barcode
        local shop

        --если нет - создаем пустую карточку товара
        if barcode_exist == nil then
            local product = self.add_product(self, {uuid=utils.generate_uuid(), name="Empty"})
            local barcode_data = {product_id=product.id, barcode=price.barcode}
            barcode = self.add_barcode(self, barcode_data)
        else
            barcode = utils.tuple_to_table(box.space.barcodes:format(), barcode_exist)
        end

        --берем uuid шопа и смотрим на его наличие в системе
        local shop_exist = box.space.shops.index.secondary:get(price.uuid)

        --если его нет - создаем
        if shop_exist == nil then
            print('Шопа нет!')
            local shop_data = {uuid=utils.generate_uuid(), name="Empty"}
            shop = self.add_shop(self, shop_data)
        else
            shop = utils.tuple_to_table(box.space.shops:format(), shop_exist)
        end

        -- собираем нашего франкенштейна
        local price_data = {id = price.id,
                            price = price.price,
                            datetime=price.datetime,
                            approved=false,
                            product_id=barcode.product_id,
                            shop_id=shop.id}
        
        local ok, tuple = self.price_model.flatten(price_data)

        if not ok then
            error("Invalid data")
        end

        box.space.prices:replace(tuple)
        
        return price_data
    end,


    get_shops = function(self)
        
        return utils.tables_to_table(box.space.shops, self.shop_model)
    end,


    get_products = function(self)
        
        return utils.tables_to_table(box.space.products, self.product_model)
    end,


    get_barcodes = function(self)
        
        return utils.tables_to_table(box.space.barcodes, self.barcode_model)
    end,


    get_goods = function(self)
        
        local goods_ =  {}
        for _, price in box.space.prices:pairs() do
            local ok, unflatted = self.price_model.unflatten(price)
            -- if unflatted.approved == true then
            --     --append price_ to goods
            -- end
            table.insert(goods_, unflatted)
        end
        
        return goods_
    end,


    get_price_history = function(self)
        
       local history = {}
       local unapproved =  box.space.prices.index.is_approved:select(false)
       for _, raw_price in pairs(unapproved) do
            local ok, price = self.price_model.unflatten(raw_price)

            local shop = box.space.shops:get(price.shop_id)

            local barcodes = {}
            for _, barcode in pairs(box.space.barcodes.index.product:select(price.product_id)) do
                table.insert(barcodes, barcode[3])
            end
            
            local dataframe = {
                barcodes=barcodes,
                PriceHistory={
                    id = price.id,
                    price = price.price,
                    shop_uuid = shop.uuid
                }
            }
            table.insert(history, dataframe)

       end

       return history
    end,

    
    get_good = function(self, barcode_value, shop_uuid)

        local barcode = box.space.barcodes.index.secondary:get(barcode_value)
        if barcode == nil then
            error("Barcode not found")
        end

        local shop = box.space.shops.index.secondary:get(shop_uuid)
        if shop == nil then
            error("Shop not found")
        end

        local product = box.space.products:get(barcode.product_id)
        local prices_ = box.space.prices.index.product:select(product.id)
        
        local shop_prices = {}
        --поиск цен только в заданном магазине
        for _, price in pairs(prices_) do
            local ok, table_price = self.price_model.unflatten(price)
            if (table_price.shop_id == shop.id) and (table_price.approved == true) then
                table.insert(shop_prices, table_price)
            end
        end

        --устанавливаем цену nil для данного магазина если цен не найдено
        if table.getn(shop_prices) == 0 then

            -- local price_data = {id=box.sequence.prices_id:next(),
            --                     price=nil,
            --                     datetime=tostring(os.date()),
            --                     approved=true,
            --                     product_id=barcode.product_id,
            --                     shop_id=shop.id}

            -- local ok, tuple = self.price_model.flatten(price_data)

            -- if not ok then
            --     error("Invalid data")
            -- end

            -- box.space.prices:replace(tuple)

            return {name=product.name, price=0}
        end

        local last_price = shop_prices[#shop_prices]

        return {name=product.name, price=last_price.price}
    end,

}

return app