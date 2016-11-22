koa= require 'koa'
cors = require 'koa-cors'
route= require 'koa-route'
koaBody= require 'koa-body'
logger= require 'koa-logger'
serve= require 'koa-static'
path= require 'path'

routers= require './router/index'

app= koa()
module.exports= app

app.use cors()
app.use logger()
app.use serve(__dirname+'/test')
app.use koaBody({
        multipart: true,
        formidable:
            maxFieldsSize: '5mb'
    })

app.use route.get '/'
app.use route.get '/member_logger', routers.member_rough_logger
app.use route.post '/member_logger', routers.member_detail_logger


unless module.parent
    app.listen 9999, -> console.log 'start koajs app on port: 9999'