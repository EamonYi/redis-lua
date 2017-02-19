local redisutil = {}

redisutil.cmd = function(cmd, key, ...)
    local red = redis:new()
    red:set_timeout(1000)
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle time
    ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return nil, false
    end

    ok, err = red:[cmd](key, ...)
    if not ok then
        ngx.say("failed to " .. cmd .. " " .. key ..": ", err)
        return nil, false
    end
    return ok
    

    -- return redis:cmd(cmd, ...)
end


return  redisutil