local avro = require('avro_schema')
local schema = require("schemes")
local log = require("log")
local auth = require("auth")
local jwt = require("jwt")
local utils = require('utils')
local checks = require('checks')
local json = require('json')
local smsc = require("smsc")

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
                {'salt', 'string'},
                {'shadow', 'string'},
                {'otp_time_created', 'unsigned'}
            },

            if_not_exists = if_not_exists,
        }
    )
    box.schema.sequence.create ('users_id',
    {if_not_exists = if_not_exists})

    users:create_index('primary', {
        type = "HASH",
        parts = {'id'},
        sequence = 'users_id',
        unique = true,
        if_not_exists = if_not_exists,
    })
    
    users:create_index('secondary', {
        type = "tree",
        parts = {'phone'},
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
        
        user.id = box.sequence.users_id:next()
        
        user.salt = 'nil'
        user.shadow = 'nil'
        user.otp_time_created = 0


        local ok, tuple = self.user_model.flatten(user)

        if not ok then
            error("Invalid data")
        end
        
        box.space.users:replace(tuple)
        
        return user
    end,


    get_user = function (self, user_id)
        
        local user = box.space.users:get(user_id)
        
        return user
    end,


    get_users = function (self)
        
        return utils.tables_to_table(box.space.users, self.user_model)
    end,


    set_otp = function (self, phone)
        
        -- get user by phone or error
        local user = box.space.users.index.secondary:get(phone)
        print(json.encode(user))
        if user == nil then
            error("No user with such a phone number!")
        end
        
        --check user token
        local token = box.space.tokens:get(user.id)
        if token ~= nil then
            error("This user already has a token!")
        end
        
        local password = self.add_password(self, user.id)
        local message = password
        local response = smsc.send_message(phone, message)

        if response.status == 200 then
            return "One-time-password sent to your phone"
        else
            return "Something wrong"
        end
    end,


    check_otp = function(self, phone, password)
        
        local user_exist = box.space.users.index.secondary:get(phone)
        
        if user_exist == nil then
            error("No user with such a phone number!")
        end

        local user = utils.tuple_to_table(box.space.users:format(), user_exist)

        -- and check lifetime
        if self.check_password(self, user, password) then
            local token = self.add_token(self, user.id)
            
            return token
        else
            error("Wrong password")
        end
    end,


    add_password = function (self, user_id)
        
        local user_exist = box.space.users:get(user_id)
        
        if user_exist == nil then
            error("User does not exist")
        end

        local pass = auth.generate_password(6)
        local otp_time_created = os.time()

        local shadow, salt = auth.create_password(pass)
        local user = utils.tuple_to_table(box.space.users:format(), user_exist)

        local tuple = box.tuple.new{user_id,
                                    user.username,
                                    user.phone,
                                    salt,
                                    shadow,
                                    otp_time_created,
                                    }

        box.space.users:replace(tuple)
        
        return pass
    end,


    check_password = function(self, user, password)
        
        return auth.check_password(user.shadow, user.salt, password)
    end,


    add_token = function(self, user_id)

        local SECRET_KEY = os.getenv("SECRET_KEY_AUTH")
        local alg = "HS256"
        local payload = {user_id = user_id, valid = true}

        local token, err = jwt.encode(payload, SECRET_KEY, alg)

        if not err == nil then
            error("Invalid data")
        end

        local tuple = box.tuple.new{user_id, token}
        box.space.tokens:replace(tuple)
        
        return token
    end,


    decode_token = function (self, incoming_token)

        local SECRET_KEY = os.getenv("SECRET_KEY_AUTH")
        local validate = true
        local decoded, err = jwt.decode(incoming_token, SECRET_KEY, validate)

        if decoded.valid ~= true then
            error("Invalid token")
        end
        
        return decoded

    end,


    get_tokens = function (self)
        
        return utils.tables_to_table(box.space.tokens, self.token_model)
    end,

}

return app