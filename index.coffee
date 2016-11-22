co= require 'co'

#====== interal modules =========
# sut= require './router/sut'
koa= require './koa'
#================================

co ->
    # yield sut.CInitSut()
    koa.listen process.env.PORT || 9998, -> console.log 'listening on port 9998'
