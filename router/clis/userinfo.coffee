#====== interal modules =========
{ userinfo }= require('../utils/database')

#================================

DinsertUserInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> userinfo.insert val
    yield yieldArray

DqueryUserInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> userinfo.findOne val
    yield yieldArray

DqueryAllUserInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> userinfo.find val, { sort: { subscribe_time: -1 } }
    yield yieldArray

DupdateUserInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> userinfo.updateById val._id, val
    yield yieldArray

DremoveUserInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> userinfo.remove val

module.exports= {
    DinsertUserInfo
    DqueryUserInfo
    DqueryAllUserInfo
    DupdateUserInfo
    DremoveUserInfo
}