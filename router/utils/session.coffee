redis= require 'redis'
wrap= require 'co-redis'

redisCo= wrap redis.createClient(16379, '10.171.131.37')

module.exports.session= redisCo
