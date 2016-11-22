redis= require 'redis'
wrap= require 'co-redis'

redisCo= wrap redis.createClient(6379, 'localhost')

module.exports.session= redisCo