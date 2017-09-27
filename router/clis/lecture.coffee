#================================
{ lecture }= require('../utils/database')

#================================

DinsertLecture= (MODELS)->
    yieldArray= MODELS.map (val)-> lecture.insert val
    yield yieldArray

DqueryLecture= (MODELS)->
    yieldArray= MODELS.map (val)-> lecture.findOne val
    yield yieldArray

DqueryAllLecture= (MODELS)->
    yieldArray= MODELS.map (val)-> lecture.find val, { sort: { LOG_TIME: -1 } }
    yield yieldArray

DupdateLecture= (MODELS)->
    yieldArray= MODELS.map (val)-> lecture.updateById val._id, val
    yield yieldArray

DremoveLecture= (MODELS)->
    yieldArray= MODELS.map (val)-> lecture.remove val

module.exports= {
    DinsertLecture
    DqueryLecture
    DqueryAllLecture
    DupdateLecture
    DremoveLecture
}
