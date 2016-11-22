#====== interal modules =========
{ areainfo }= require('../utils/database')

#================================

DinsertAreaInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> areainfo.insert val
    yield yieldArray
    
DinsertAllAreaInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> areainfo.insert val
    yield yieldArray

DqueryAreaInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> areainfo.findOne val
    yield yieldArray

DqueryAllAreaInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> areainfo.find val, { sort: { code: 1 } }
    yield yieldArray

DupdateAreaInfo= (MODELS)->
    yieldArray= MODELS.map (val)-> areainfo.updateById val._id, val
    yield yieldArray

module.exports= {
    DinsertAreaInfo
    DinsertAllAreaInfo
    DqueryAreaInfo
    DqueryAllAreaInfo
    DupdateAreaInfo
}