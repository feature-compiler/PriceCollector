local http = require('curl').http()
local json = require('json')

local URI = 'http://127.0.0.1/api'
function request(method, body)
  local resp = http:request(
      method, URI, body
  )

  print(resp.body)

end

request('POST', '{"method": "add", "params": ['..json.encode(pokemon)..']}')
