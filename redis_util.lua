local redisutil = {}

redisutil.cmd = function(cmd, key, ...)
    local red = redis:new()
    red:set_timeout(1000)
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    ok, err = red[cmd](red, key, ...)
    -- ok, err = red:[cmd](key, ...)
    if not ok then
        ngx.say("failed to " .. cmd .. " " .. key ..": ", err)
        return nil, false
    end

    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle time
    ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return nil, false
    end

    return ok
    

    -- return redis:cmd(cmd, ...)
end

redisutil.pipline = function(cmd, key, ...)
    local red = redis:new()
    red:set_timeout(1000)

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    -- red:init_pipeline()
    -- red:set("cat", "Marry")
    -- red:set("horse", "Bob")
    -- red:get("cat")
    -- red:get("horse")
    ok, err = red:multi()
    ngx.say(ok, err)
    ok, err = red:set("cat", "Marry")
    ngx.say(ok, err)
    ok, err = red:set("horse", "Bob")
    ngx.say(ok, err)
    ok, err = red:get("cat")
    ngx.say(ok, err)
    ok, err = red:get("horse")
    ngx.say(ok, err)
    ok, err = red:exec()
    ngx.say("exec " .. cjson.encode(ok), err)
    red:close()
    return

    -- local results, err = red:commit_pipeline()
    -- if not results then
    --     ngx.say("failed to commit the pipelined requests: ", err)
    --     return
    -- end

    -- for i, res in ipairs(results) do
    --     if type(res) == "table" then
    --         if res[1] == false then
    --             ngx.say("failed to run command ", i, ": ", res[2])
    --         else
    --             -- process the table value
    --         end
    --     else
    --         -- process the scalar value
    --     end
    -- end

    -- -- put it into the connection pool of size 100,
    -- -- with 10 seconds max idle time
    -- local ok, err = red:set_keepalive(10000, 100)
    -- if not ok then
    --     ngx.say("failed to set keepalive: ", err)
    --     return
    -- end

    -- -- or just close the connection right away:
    -- -- local ok, err = red:close()
    -- -- if not ok then
    -- --     ngx.say("failed to close: ", err)
    -- --     return
    -- -- end
end

-- -- pipline in redis.lua sames to be non-atomic, so it is needed to get a multi-exec fucntion
-- redisutil.multi = function(cmds)
--     local red = redis:new()
--     red:set_timeout(1000)

--     local ok, err = red:connect("127.0.0.1", 6379)
--     if not ok then
--         ngx.say("failed to connect: ", err)
--         return
--     end
--     red:multi()

--     local cmd_tmp
--     for 
-- end


return  redisutil