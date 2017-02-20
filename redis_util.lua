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

redis_util.eval = function(shm_name, script_tb, ...)
    if not (shm_name and script_tb.script) then 
        nlog.warn("redis eval error, shm_name=" .. tostring(shm_name) .. ", script=" .. string.sub(script_tb.script,1, 900))
        return nil, -1
    end
    local debug_str = "shm_name:"..shm_name .. " script[" .. string.sub(script_tb.script, 1, 50)
    for k,v in ipairs({...}) do
        debug_str = debug_str .. " " .. v
    end
    debug_str = debug_str .. "]"

    local red, err = redis_util.connect_db(shm_name, debug_str)
    if 0 ~= err then
        return nil, err
    end

    --exec
    local ret = nil
    if "string" == type(script_tb.sha1) and string.len(script_tb.sha1) > 0 then
        ret, err = red:evalsha(script_tb.sha1, ...)
        ngx.say("evalsha:" .. cjson.encode(ret))
    else
        ret, err = red["script"](red,"load", script_tb.script)
        if "string" == type(ret) and string.len(ret) > 0 then
            script_tb.sha1 = ret
        end
        ret, err = red:evalsha(script_tb.sha1, ...)
        ngx.say("evalsha:" .. cjson.encode(ret))
    end

    local ok = nil
    ok, err = red:set_keepalive(redisconf.keepalive.idle_time, redisconf.keepalive.pool_size)
    if not ok then
        -- 保持连接失败并不会影响实际数据
        nlog.warn("set_keepalive failed!")
    end

    return ret
end

-- atom
redis_util.multi_exec = function(shm_name, cmd_tb)
    if not (shm_name and #cmd_tb > 0) then 
        nlog.warn("redis eval error, shm_name=" .. tostring(shm_name) .. ", cmd_tb=" .. cjson.encode(cmd_tb))
        return nil, -1
    end
    local debug_str = "shm_name:"..shm_name .. " cmd_tb[" .. cjson.encode(cmd_tb)
    debug_str = debug_str .. "]"

    local red, err = redis_util.connect_db(shm_name, debug_str)
    if 0 ~= err then
        return nil, err
    end

    local ret = nil
    ret, err = red:multi()
    if "ok" ~= ret then
        return nil, -1
    end
    local cmd_tmp = nil
    for _, cmd_tmp in pairs(cmd_tb) do
        if #cmd_tmp == 1 then
            ret, err = red[cmd_tmp[1]](red)
        else
            ret, err = red[cmd_tmp[1]](red, unpack(cmd_tmp, 2))
        end
        if "QUEUEND" ~= ret then
            return nil, -1
        end
    end
    ret, err = red:exec()

    local ok = nil
    ok, err = red:set_keepalive(redisconf.keepalive.idle_time, redisconf.keepalive.pool_size)
    if not ok then
        -- 保持连接失败并不会影响实际数据
        nlog.warn("set_keepalive failed!")
    end

    if nil == ret then
        return ret, 0
    end

    return ret
end



return  redisutil
