local checks = require('checks')
local errors = require('errors')
-- класс ошибок хранилища
local err_storage = errors.new_class("Storage error")

local role_name = 'app.roles.user_storage'

-- кортеж в таблицу согласно схеме хранения
local function tuple_to_table(format, tuple)
    local map = {}
    for i, v in ipairs(format) do
        map[v.name] = tuple[i]
    end
    return map
end

local function init_space()
    local user = box.schema.space.create(
        'user',
        {
            -- формат хранимых кортежей
            format = {
                {'id', 'unsigned'},
                {'bucket_id', 'unsigned'},
                {'username', 'string'},
                {'phone', 'string'},
                {'is_super', 'boolean'}
            },

            if_not_exists = true,
        }
    )

    -- индекс по id
    user:create_index('id', {
        parts = {'id'},
        if_not_exists = true,
    })


    user:create_index('bucket_id', {
        parts = {'bucket_id'},
        unique = false,
        if_not_exists = true,
    })
end

local function user_add(user)
    checks('table')

    -- Проверяем существование пользователя с таким id
    local exist = box.space.user:get(user.id)
    if exist ~= nil then
        return {ok = false, error = err_storage:new("User already exist")}
    end

    box.space.user:insert(box.space.user:frommap(user))

    return {ok = true, error = nil}
end

local function user_get(id)
    checks('number')

    local user = box.space.user:get(id)
    if user == nil then
        return {user = nil, error = err_storage:new("User not found!")}
    end

    user = tuple_to_table(box.space.user:format(), user)
    
    user.bucket_id = nil
    user.phone = nil
    user.username = nil
    user.is_super = nil

    return {user = user, error = nil}
end


local function init(opts)
    if opts.is_master then
        init_space()

        box.schema.func.create('user_add', {if_not_exists = true})
        box.schema.func.create('user_get', {if_not_exists = true})
    end

    rawset(_G, 'user_add', user_add)
    rawset(_G, 'user_get', user_get)
    return true
end

return {
    role_name = role_name,
    init = init,
    utils = {
        user_add = user_add,
        user_get = user_get,
    },
    dependencies = {
        'cartridge.roles.vshard-storage'
    }
}
