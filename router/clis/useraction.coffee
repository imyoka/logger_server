#====== interal modules =========
{ useraction }= require('../utils/database')

#================================

DinsertUserAction= (MODELS)->
    yieldArray= MODELS.map (val)-> useraction.insert val
    yield yieldArray
    
DqueryUserAction= (MODELS)->
    yieldArray= MODELS.map (val)-> useraction.findOne val
    yield yieldArray

DqueryAllUserAction= (MODELS)->
    yieldArray= MODELS.map (val)-> useraction.find val, { sort: { updatetime: -1 } }
    yield yieldArray

DupdateUserAction= (MODELS)->
    yieldArray= MODELS.map (val)-> useraction.updateById val._id, val
    yield yieldArray

module.exports= {
    DinsertUserAction
    DqueryUserAction
    DqueryAllUserAction
    DupdateUserAction
}