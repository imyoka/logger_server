#====== interal modules =========
{ member }= require('../utils/database')

#================================

DinsertMember= (MODELS)->
    yieldArray= MODELS.map (val)-> member.insert val
    yield yieldArray

DqueryMember= (MODELS)->
    yieldArray= MODELS.map (val)-> member.findOne val
    yield yieldArray

DqueryAllMember= (MODELS)->
    yieldArray= MODELS.map (val)-> member.find val, { sort: { LOG_TIME: -1 } }
    yield yieldArray

DupdateMember= (MODELS)->
    yieldArray= MODELS.map (val)-> member.updateById val._id, val
    yield yieldArray

DremoveMember= (MODELS)->
    yieldArray= MODELS.map (val)-> member.remove val

module.exports= {
    DinsertMember
    DqueryMember
    DqueryAllMember
    DupdateMember
    DremoveMember
}