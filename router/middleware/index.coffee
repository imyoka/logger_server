sut= require '../sut'

ensureAccessToken= (next)->
    yield sut.CInitSut()
    yield return

module.exports= {
    ensureAccessToken
}