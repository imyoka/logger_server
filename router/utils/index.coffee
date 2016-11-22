#====== interal modules =========
{ serverinfo }= require('./database')

#================================

tools=
    fix2: (num)-> return Math.round(num*100)/100
    getms2Seconds: (millionseconds)-> millionseconds / 1000
    getSeconds2ms: (seconds)-> seconds * 1000
    getrandomNum: (length)-> ~~(Math.random()*10*length%length)
    isDoomsday: (daynum, atomtime)->
        currentTime= new Date().getDate()
        startTime= new Date(atomtime).getDate()
        currentMonth= new Date().getMonth()
        startMonth= new Date(atomtime).getMonth()
        currentYear= new Date().getYear()
        startYear= new Date().getYear()
        unless ((currentTime- startTime < daynum and currentMonth- startMonth is 0) and currentMonth- startMonth > 0 and currentYear- startYear is 0) and currentYear- startYear> 0
            console.log 'true, expired', new Date(atomtime).toLocaleString(), currentTime- startTime, currentMonth- startMonth
            return true
        else
            console.log 'not yet expired', new Date(atomtime).toLocaleString(), currentTime- startTime, currentMonth- startMonth
            return false
    isTokenExpired: (access_token)->
        currentTime= new Date().getTime()
        keyObj= yield serverinfo.findOne { access_token: access_token }
        access_token= keyObj.access_token

        # justify whether expired
        expires_in= keyObj.expires_in
        startTime= keyObj.startTime
        if currentTime- startTime > @getSeconds2ms(expires_in)
            # modify the expire status
            updateObj= keyObj
            updateObj.is_expires= true

            yield serverinfo.updateById keyObj._id, updateObj
            return updateObj.is_expires
        else return access_token
    isTicketExpired: (jsapi_ticket)->
        currentTime= new Date().getTime()
        keyObj= yield serverinfo.findOne { jsapi_ticket: jsapi_ticket }
        jsapi_ticket= keyObj.jsapi_ticket

        # justify whether expired
        expires_in= keyObj.expires_in
        startTime= keyObj.startTime
        if currentTime- startTime > @getSeconds2ms(expires_in)
            # modify the expire status
            updateObj= keyObj
            updateObj.is_expires= true
            yield serverinfo.updateById keyObj._id, updateObj
            return updateObj.is_expires
        else return jsapi_ticket
    getNonceStr: ()->
        return Math.random().toString(36).substr(2, 15)
    getTimestamp: ()->
        timestamp= ''+ new Date().getTime()
        return timestamp.substr(0, 10)
    getASCIIString: (ARGS, ISKEYLOWCASE)->
        keys= Object.keys ARGS
        keys= keys.sort()
        newArgs = {}
        keys.forEach (key)->
            if ISKEYLOWCASE then newArgs[key.toLowerCase()]= ARGS[key]
            else newArgs[key]= ARGS[key]
        string = ''
        for key, val of newArgs
            string+= '&' + key + '=' + val
        string = string.substr(1)
        return string
    getSHA1String: (ARGS)->
        asciiString= @getASCIIString(ARGS, true)
        bufString= Buffer asciiString # 处理中文
        crypto= require 'crypto'
        SHA1String= crypto.createHash 'sha1'
                        .update bufString
                        .digest 'hex'
        return SHA1String
    getMD5String: (ARGS, KEY)->
        asciiString= @getASCIIString(ARGS, true)
        asciiString+= "&key=#{KEY}"
        bufString= Buffer asciiString # 处理中文
        crypto= require 'crypto'
        MD5String= crypto.createHash 'md5'
                        .update bufString
                        .digest 'hex'
        return MD5String.toUpperCase()
    getRawMD5String: (ARGS, KEY)->
        asciiString= @getASCIIString(ARGS, false)
        asciiString+= "&key=#{KEY}"
        bufString= Buffer asciiString # 处理中文
        crypto= require 'crypto'
        MD5String= crypto.createHash 'md5'
                        .update bufString
                        .digest 'hex'
        return MD5String.toUpperCase()
    getParsedXML: (XML)->
        xml2js= require 'xml2js'
        return (done)-> xml2js.parseString XML, {trim: true}, done
    getUnifiedXml: (ORDER_INFO)->
        tpl = ['<xml>']
        for key, val of ORDER_INFO
            tpl.push "<#{key}><![CDATA[#{val}]]></#{key}>"
        tpl.push '</xml>'
        unifiedXml= tpl.join('')
        return unifiedXml
    getFormatMsg: (RESULT)->
        message= {}
        if 'object' is typeof RESULT
            for key, val of RESULT
                if (not val instanceof Array) or (val.length is 0) then continue
                if val.length is 1
                    val= val[0]
                    if 'object' is typeof val then message[key]= @getFormatMsg val
                    else message[key]= (val or '').trim()
                else
                    message[key]= []
                    RESULT[key].forEach (item)-> message[key].push @getFormatMsg(item)
        return message
    getRandomRemark: (TIMESTAMP)->
        EIN = ['A', 'L', 'C', 'H', 'S']
        ZWEI= ['T', 'S', 'H', 'E', 'R']
        DREI= ['M', 'E', 'I', 'V', 'A']
        data= TIMESTAMP.match /\d{3}(\d{3})(\d{4})/i
        prefix= data[1]
        subfix= data[2]
        PreName= prefix.split('').map (one)->
            ix= ~~one%EIN.length
            EIN[ix]
        .join ''
        return "#{PreName}#{subfix}"

module.exports= Object.create tools