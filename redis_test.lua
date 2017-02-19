
local args = ngx.req.get_uri_args()
local key = args.key 

if nil == key or "" == key then
    ngx.exit(406)
end

local incr_str = '
local exist_key = redis.call("exists", KEYS[1])
if tonumber(exist_key) == 1 then
    return redis.call("incr", KEYS[1])
end
return 0
'

ngx.say(redisutil.cmd('eval',incr_str,'123'))
redisutil.pipline() 