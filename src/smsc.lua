M = {}
local http = require('http.client')


local login = "zo_sms"
local password = "skU40iR"
local phone = "89107138699"
local message = "test message"
local sender = "ZELENOSTROV"

local function check_number(phone)
    if string.find(phone,"8") ~= 1 then
        error("Phone should be starts with '8' !!!")
    end
end

local function request(URL)
    local response = http.get(URL)
    return response
end

local function send_message(phone, message)
    check_number(phone)
    local url = string.format("https://smsc.ru/sys/send.php?login=%s&psw=%s&phones=%s&mes=%s&sender=%s&fmt=3", login, password, phone, string.gsub(message, "%s+", "_"), sender)
    local response = request(url)
    return response
end


M.send_message = send_message

return M