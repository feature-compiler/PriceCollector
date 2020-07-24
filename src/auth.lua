-- Модуль проверки аргументов в функции
local checks = require('checks')
-- Модуль с криптографическими функциями
local digest = require('digest')

local SALT_LENGTH = 16


local function generate_salt(length)
    
    return digest.base64_encode(
        digest.urandom(length - bit.rshift(length, 2)),
        {nopad=true, nowrap=true}
    ):sub(1, length)
end

local function password_digest(password, salt)
    
    checks('string', 'string')
    
    return digest.pbkdf2(password, salt)
end

local function generate_password(length)
    
    math.randomseed(os.clock()*100000000000)
	local res = ""
	for i = 1, length do
		res = res .. math.random(1, 9)
	end
    
    return res
end


local function create_password(password)
    
    checks('string')

    local salt = generate_salt(SALT_LENGTH)

    local shadow = password_digest(password, salt)

    return shadow, salt
end


local function check_password(shadow, salt, password)
    
    return shadow == password_digest(password, salt)
end

return {
    create_password = create_password,
    check_password = check_password,
    generate_password = generate_password,
}