local avro = require('avro_schema')
local schema = require("schemes")
local log = require("log")

local app_name = 'prices'

local app = {
    
    price_model = {},

    start = function (self)
        box.once('init', function ()
            box.schema.create_space("prices")
            box.space.prices:create_index(
                "primary", {type = "hash", parts = {1, "unsigned"}}
            )
        end)

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