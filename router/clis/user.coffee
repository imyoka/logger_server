#====== interal modules =========
{ usercontact }= require('../utils/database')

#================================

DinsertContact= (MODELS)->
    yieldArray= MODELS.map (val)-> usercontact.insert val
    yield yieldArray

DqueryContact= (MODELS)->
    yieldArray= MODELS.map (val)-> usercontact.findOne val
    yield yieldArray

DqueryAllContact= (MODELS)->
    yieldArray= MODELS.map (val)-> usercontact.find val
    yield yieldArray

module.exports= {
    DinsertContact
    DqueryContact
    DqueryAllContact
}