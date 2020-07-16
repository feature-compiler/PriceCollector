local cartridge = require('cartridge')
local errors = require('errors')
local log = require('log')

local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")

local role_name = 'app.roles.user_api'


local function json_response(req, json, status) 
    local resp = req:render({json = json})
    resp.status = status
    return resp
end


local function internal_error_response(req, error)
    local resp = json_response(req, {
        info = "Internal error",
        error = error
    }, 500)
    return resp
end


local function user_not_found_response(req)
    local resp = json_response(req, {
        info = "User not found"
    }, 404)
    return resp
end


local function user_conflict_response(req)
    local resp = json_response(req, {
        info = "User already exist"
    }, 409)
    return resp
end


local function storage_error_response(req, error)
    if error.err == "Profile already exist" then
        return user_conflict_response(req)
    elseif error.err == "Profile not found" then
        return user_not_found_response(req)
    else
        return internal_error_response(req, error)
    end
end


local function http_test(req)

    --local data = req:json()
    return json_response(req, {info = "Successfully tested"}, 201)
end


local function http_user_add(req)
    local user = req:json()

    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(user.id)
    user.bucket_id = bucket_id

    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'write',
        'user_add',
        {user}
    )

    if error then
        return internal_error_response(req, error)
    end
    if resp.error then
        return storage_error_response(req, resp.error)
    end
    
    return json_response(req, {info = "Successfully created"}, 201)
end

local function http_user_get(req)
    local id = tonumber(req:stash('id'))
    --local password = req:json().password
    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(id)

    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'read',
        'user_get',
        {id}
    )

    if error then
        return internal_error_response(req, error)
    end
    if resp.error then
        return storage_error_response(req, resp.error)
    end

    return json_response(req, resp.profile, 200)
end


local function init(opts)
    if opts.is_master then
        box.schema.user.grant('guest',
            'read,write',
            'universe',
            nil, { if_not_exists = true }
        )
    end

    local httpd = cartridge.service_get('httpd')

    if not httpd then
        return nil, err_httpd:new("not found")
    end

    log.info("Starting httpd")

    httpd:route(
        { path = '/user', method = 'POST', public = true },
        http_user_add
    )
    httpd:route(
        { path = '/user/:id', method = 'GET', public = true },
        http_user_get
    )
    httpd:route(
        {path = '/test', method = 'GET', public = true},
        http_test
    )

    log.info("Created httpd")
    return true
end

return {
    role_name = role_name,
    init = init,
    dependencies = {
        'cartridge.roles.vshard-router'
    }
}