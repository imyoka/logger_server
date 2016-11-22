#====== interal modules =========
{ productorder }= require('../utils/database')

#================================

DinsertOrder= (MODELS)->
    yieldArray= MODELS.map (val)-> productorder.insert val
    yield yieldArray

DqueryOrder= (MODELS)->
    yieldArray= MODELS.map (val)-> productorder.findOne val
    yield yieldArray

DqueryAllOrder= (MODELS)->
    yieldArray= MODELS.map (val)-> productorder.find val
    yield yieldArray

module.exports= {
    DinsertOrder
    DqueryOrder
    DqueryAllOrder
}