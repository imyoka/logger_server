#====== interal modules =========
{ userlocation }= require('../utils/database')

#================================

DinsertLocation= (MODELS)->
    yieldArray= MODELS.map (val)-> userlocation.insert val
    yield yieldArray

DqueryLocation= (MODELS)->
    yieldArray= MODELS.map (val)-> userlocation.findOne val, { sort: { time: -1 } }
    yield yieldArray

DqueryAllLocation= (MODELS)->
    yieldArray= MODELS.map (val)-> userlocation.find val
    yield yieldArray

module.exports= {
    DinsertLocation
    DqueryLocation
    DqueryAllLocation
}