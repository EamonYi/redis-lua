local redisutil = {}

redisutil.cmd = function(cmd, key, value)
    return redis.cmd(cmd, key, value)
end