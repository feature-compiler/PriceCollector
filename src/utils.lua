M = {}
local json = require('json')

-- Функция заполняющая недостающие поля таблицы minor из таблицы major
local function complete_table(major, minor)
    for k, v in pairs(major) do
        if minor[k] == nil then
            minor[k] = v
        end
    end
end

-- Функция преобразующая кортеж в таблицу согласно схеме хранения
local function tuple_to_table(format, tuple)
    local map = {}
    for i, v in ipairs(format) do
        map[v.name] = tuple[i]
    end
    return map
end


local function tables_to_table(box_space)
    local table_ = {}
    for key, obj in box_space:pairs() do
        table.insert(table_, tuple_to_table(box_space:format(), obj))
    end
    return table_
end


local function error_handler (err)
    return err
  end

local function read_json(filename)
    local file = io.open(filename..".json", "r")
    local table
    if file then
      table = json.decode(file:read("*all"))
      file:close()
    end
    return table
end

local function json_response(lua_object)
    return json.encode(lua_object)
end

local function generate_uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

  
M.read_json = read_json
M.tables_to_table = tables_to_table
M.json_response = json_response
M.complete_table = complete_table
M.tuple_to_table = tuple_to_table
M.error_handler = error_handler
M.generate_uuid = generate_uuid

return M