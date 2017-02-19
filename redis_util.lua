local redisutil = {}

redisutil.cmd = function(key, value)
    return redis.cmd('get', 'test')
end