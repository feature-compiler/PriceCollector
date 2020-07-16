local avro = require('avro_schema')
local schema = require("schemes")
local log = require("log")

local app_name = 'users'

local app = {

    user_model = {},
    
    start = function (self)
        box.once('init', function ()
            box.schema.create_space("users")
            box.space.users:create_index(
                "primary", {type = "hash", parts = {1, "unsigned"}}
            )
        end)

        local ok_u, user = avro.create(schema.user)
        

        if ok_u then
            local ok_cu, compiled_user = avro.compile(user)
            
            if ok_cu then
                self.user_model = compiled_user

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

    add_user = function (self, user)
        local ok, tuple = self.user_model.flatten(user)

        if not ok then
            return false
        end
        box.space.users:replace(tuple)
        return true
    end,

    get_user = function (self, user_id)
        local user_tuple = box.space.users:get(user_id)
        if user_tuple == nil then
            return false
        end
        return user_tuple
    
    
end


}

return app