views= require 'co-views'
parse= require 'raw-body'
path= require 'path'
#====== interal modules =========
sut= require './sut'
$= require './utils'
{ ensureAccessToken }= require './middleware/index'
{ session }= require './utils/session'
{ DinsertMember, DqueryMember, DqueryAllMember, DupdateMember, DremoveMember } = require './clis/member'
#================================
render= views(__dirname+ '/../views/', { ext: 'jade'})

# rough logger
# [format]
# ?logname=[name]&uri=[uri]&params=[params]&page=[page]
member_rough_logger= ->
    url= require 'url'
    { logname, uri, params, page }= url.parse(@req.url, true).query
    # filter
    unless logname? and uri? and page?
        @body= 'fail'
        yield return

    logData=
        LOG_NAME: logname
        LOG_URI: uri
        LOG_PARAMS: params
        LOG_PAGE: page
    storeLogger= Object.assign logData, {
        LOG_TYPE: 'ROUGH'
        LOG_TIME: "#{new Date().getTime()}"
    }

    yield from DinsertMember [storeLogger]
    @body= 'success'
    yield return

# detail logger
# [format]
# stringify
# {
#   name: [log name]
#   uri: [request uri]
#   params: [request parameters]
#   page: [current page]
#   ua: [useragent]
#   ip: [userip]
# }
member_detail_logger= ->
    # 获取client传递过来的消息
    { logname, uri, params, page, ua, ip } = @request.body
    # filter
    unless logname? and uri? and page?
        @body= 'fail'
        yield return

    logData=
        LOG_NAME: logname
        LOG_URI: uri
        LOG_PARAMS: params
        LOG_PAGE: page
        LOG_UA: ua
        LOG_IP: ip
    storeLogger= Object.assign @request.body, logData, {
        LOG_TYPE: 'DETAIL'
        LOG_TIME: "#{new Date().getTime()}"
    }

    yield from DinsertMember [storeLogger]
    @body= 'success'
    yield return

module.exports= {
    member_rough_logger
    member_detail_logger
}