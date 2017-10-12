redis= require 'redis'
wrap= require 'co-redis'

rdhost = process.env.RDHOST
rdport = process.env.RDPORT

redisCo= wrap redis.createClient(rdport, rdhost)

module.exports.session= redisCo
