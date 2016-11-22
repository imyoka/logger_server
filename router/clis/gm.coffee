co= require('co') 
gm= require('gm').subClass({imageMagick: true})
path= require('path')
mkdirp= require('mkdirp')

noresizeURI= (URI, DEST)->
    mkdirp.sync path.dirname(DEST)
    return (done)->
        gm URI
        .noProfile()
        .write DEST+ '.jpg', done

resizeURI= (URI, width, height, DEST, isforced)->
    mkdirp.sync path.dirname(DEST)
    return (done)->
        if isforced
            gm URI
            .resize width, height, '!'
            .noProfile()
            .write DEST+ '.jpg', done
        else
            gm URI
            .resize width
            .noProfile()
            .write DEST+ '.jpg', done

resizeBuf= (BUF, width, height, DEST)->
    mkdirp.sync path.dirname(DEST)
    return (done)->
        gm BUF
        .resize width, height, '!'
        .noProfile()
        .write DEST+ '.jpg', done

module.exports= {
    noresizeURI
    resizeURI
    resizeBuf
}