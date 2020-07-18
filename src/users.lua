local avro = require('avro_schema')
local schema = require("schemes")
local log = require("log")
local auth = require("auth")
local jwt = require("jwt")
local utils = require('utils')

local app_name = 'users'

local function init_space()

    local if_not_exists = true

    local users = box.schema.space.create(
        'users',
        {
            -- формат хранимых кортежей
            format = {
                {'id', 'unsigned'},
                {'username', 'string'},
                {'phone','string'},
                {'is_super', 'boolean'},
                {'salt', 'string'},
                {'shadow', 'string'},
            },

            if_not_exists = if_not_exists,
        }
    )

    users:create_index('primary', {
        type = "hash",
        parts = {'id'},
        if_not_exists = if_not_exists,
    })

    users:create_index('secondary', {
        type = "hash",
        parts = {'username'},
        if_not_exists = if_not_exists,
    })

    local tokens = box.schema.space.create(
        'tokens',
        {
            format = {
                {'user_id', 'unsigned'},
                {'jwt', 'string'},
            },

            if_not_exists = if_not_exists,
        }
    )

    tokens:create_index('primary', {
        type = "hash",
        parts = {'user_id'},
        if_not_exists = if_not_exists,
    })

end

local app = {

    user_model = {};
    token_model = {};
    
    
    start = function (self)

        init_space()

        local ok_u, user = avro.create(schema.user)
        local ok_t, token = avro.create(schema.token)
        

        if ok_u and ok_t then
            local ok_cu, compiled_user = avro.compile(user)
            local ok_ct, compiled_token = avro.compile(token)
            
            if ok_cu and ok_ct then
                self.user_model = compiled_user
                self.token_model = compiled_token

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
        return user_tuple
    end,
        
    add_token = function(self, user_id)
        --check existing data
        local user_exist = box.space.users:get(user_id)
        if user_exist == nil then
            return false
        end

        local SECRET_KEY = os.getenv("SECRET_KEY_AUTH")
        local alg = "HS256"
        local payload = {user_id = user_id, iss = "auth"}

        local token, err = jwt.encode(payload, SECRET_KEY, alg)
        print(token)

        if not err == nil then
            return false
        end

        local tuple = box.tuple.new{user_id, token}
        box.space.tokens:replace(tuple)
        return true

        -- local shadow, salt = auth.create_password(new_token)
        -- local token = {user_id = user_id, salt = salt, shadow = shadow}
        -- local ok, tuple = self.token_model.flatten(token)
        -- if not ok then
        --     return false
        -- end
        -- box.space.tokens:replace(tuple)
        -- return true
    end,

    check_token = function (self, incoming_token)

        local SECRET_KEY = os.getenv("SECRET_KEY_AUTH")
        local validate = true
        local decoded, err = jwt.decode(incoming_token, SECRET_KEY, validate)

        if not err == nil then
            return false
        end
        
        return decoded
        --user_tuple = box.space.users:get(user_id)
        --check existing data
        -- local user_exist = box.space.users.index.secondary:get(username)
        -- if user_exist == nil then
        --     return false
        -- end
        -- local user = utils.tuple_to_table(box.space.users:format(), user_exist)

        -- local token_exist = box.space.tokens:get(user.id)
        -- if token_exist == nil then
        --     return false
        -- end

        -- --token validation
        -- local token = utils.tuple_to_table(box.space.tokens:format(), token_exist)
        -- if not auth.check_password(token.shadow, token.salt, incoming_token) then
        --     return false
        -- end
        
        -- return true

    end

}

return app