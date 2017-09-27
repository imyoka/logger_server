views= require 'co-views'
parse= require 'raw-body'
path= require 'path'
#====== interal modules =========
sut= require './sut'
$= require './utils'
{ ensureAccessToken }= require './middleware/index'
{ session }= require './utils/session'
{ DinsertMember, DqueryMember, DqueryAllMember, DupdateMember, DremoveMember } = require './clis/member'
{ DinsertLecture, DqueryLecture, DqueryAllLecture, DupdateLecture, DremoveLecture } = require './clis/lecture'
#================================
render= views(__dirname+ '/../views/', { ext: 'jade'})

# rough logger
# [format]
# ?logname=[name]&uri=[uri]&params=[params]&page=[page]
member_rough_logger= ()->
    url= require 'url'
    { logname, uri, params }= url.parse(@req.url, true).query
    # filter
    unless logname? and uri?
        @body= 'fail'
        yield return

    logData=
        LOG_NAME: logname
        LOG_URI: uri
        LOG_PARAMS: params
        LOG_PAGE: @req['headers']['referer']
        LOG_IP: @req['headers']['x-real-ip'] || @req['headers']['x-forwarded-for']
        LOG_UA: @req['headers']['user-agent']
    storeLogger= Object.assign logData, {
        LOG_TYPE: 'ROUGH'
        LOG_TIME: "#{new Date().getTime()}"
    }
    session.select(10)
    session.publish 'weblog', JSON.stringify(storeLogger)
    console.log 'member_rough_logger'
    #console.log @req['headers']['x-real-ip'] || @req['headers']['x-forwarded-for']
    #console.log @req['headers']['referer']
    #console.log @req['headers']['user-agent']

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
    storeLogger= Object.assign logData, {
        LOG_TYPE: 'DETAIL'
        LOG_TIME: "#{new Date().getTime()}"
    }

    session.select(10)
    session.publish 'weblog', JSON.stringify(storeLogger)
    console.log 'member_detail_logger'

    yield from DinsertMember [storeLogger]
    @body= 'success'
    yield return

lecture_rough_logger= ->
    url= require 'url'
    { logname, union_id, course_id, type }= url.parse(@req.url, true).query
    # filter
    unless logname? and union_id? and course_id? and type?
        @body= 'fail'
        yield return

    logData=
        LOG_NAME: logname
        UNION_ID: union_id
        COURSE_ID: course_id
    storeLogger= Object.assign logData, {
        LOG_TYPE: type
        LOG_TIME: new Date().toLocaleString()
    }

    yield from DinsertMember [storeLogger]
    @body= 'success'
    yield return

module.exports= {
    member_rough_logger
    member_detail_logger

    lecture_rough_logger
}
