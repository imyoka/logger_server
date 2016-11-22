superagent = require 'superagent'
co= require 'co'
#====== interal modules =========
{ serverinfo, userinfo }= require('./utils/database')
$= require('./utils')
INFOTEMPLATE= require('./utils/infotemplate')
{ gov }= require('./crawclis')

#================================

SuT=
    # 消息回复
    DInitSut: ()->
        yield serverinfo.remove { is_expires: false }
    CInitSut: ()->
        # init access_token && jsapi_ticket
        @access_token= yield sut.QAccess_token()
        @jsapi_ticket= yield sut.QTicket()
        return
    QAccess_token: ()->
        keyObj= yield serverinfo.findOne { name: 'token', is_expires: false }
        unless keyObj?
            console.log 'timeout after 7200, get access_token, shouldnt here'
            reqStr= "#{@host}/cgi-bin/token?grant_type=client_credential&appid=#{@appid}&secret=#{@appsecret}"
            callback= yield superagent.get(reqStr)

            # parse
            val= JSON.parse callback.text
            access_token= val.access_token
            expires_in= val.expires_in

            # save
            startTime= new Date().getTime()
            obj=
                name: 'token', access_token: access_token, expires_in: expires_in, startTime: startTime, is_expires: false
            yield serverinfo.insert obj
            return access_token
        else
            # 判断查询结果是否过期失效，是则更新状态，重新调用当前函数
            access_token= yield $.isTokenExpired(keyObj.access_token)
            console.log 'timeout after 7200, get access_token, here is right', access_token
            if typeof access_token isnt 'string'
                yield sut.DInitSut()
                return yield @QAccess_token()
            return access_token
        
    QServer_ipList: ()->
        reqStr= "#{@host}/cgi-bin/getcallbackip?access_token=#{@access_token}"
        callback= yield superagent.get(reqStr)

        # parse
        val= JSON.parse callback.text
        ipList= val.ip_list
        return ipList

    # Group Panel
    CGroup: ()->
        reqStr= "#{@host}/cgi-bin/groups/create?access_token=#{@access_token}"
        Params=
            group: { name: 'test' }
        callback= yield superagent.post(reqStr, Params)
        val= JSON.parse callback.text
        return val
    QGroupList: ()->
        reqStr= "#{@host}/cgi-bin/groups/get?access_token=#{@access_token}"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text
        groupList= val.groups
        return groupList
    UGroupName: (GroupID, NEWNAME)->
        reqStr= "#{@host}/cgi-bin/groups/update?access_token=#{@access_token}"
        Params=
            group: { id: GroupID, name: NEWNAME }
        callback= yield superagent.post(reqStr, Params)
        val= JSON.parse callback.text
        if val.errcode is 0 then return true
        else return { errorCode: val.errcode, errorMsg: val.errmsg }
    # User Panel
    QUserList: (NEXT_OPENID)->
        if NEXT_OPENID?
            reqStr= "#{@host}/cgi-bin/user/get?access_token=#{@access_token}&next_openid=#{NEXT_OPENID}"
        else
            reqStr= "#{@host}/cgi-bin/user/get?access_token=#{@access_token}"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text

        # parse
        userlist= val.data.openid
        next_openid= val.next_openid
        if userlist[userlist.length- 1] is next_openid
            return userlist
        else
            if next_openid is ''
                return userlist
            else
                @QUserList(next_openid)
    QUserInfo: (OPENID)->
        reqStr= "#{@host}/cgi-bin/user/info?access_token=#{@access_token}&openid=#{OPENID}&lang=zh_CN"
        callback= yield superagent.get(reqStr)
        result= JSON.parse callback.text
        console.log result
        return result
    # 最多支持一次拉取100条
    QUserInfoList: (USER_LIST)->
        reqStr= "#{@host}/cgi-bin/user/info/batchget?access_token=#{@access_token}"
        Params=
            user_list: USER_LIST
        callback= yield superagent.post(reqStr, Params)
        val= JSON.parse callback.text
        result= val.user_info_list
        return result

    CMenu: (BTN, MATCH_RULE)->
        reqStr= "#{@host}/cgi-bin/menu/addconditional?access_token=#{@access_token}"
        Params=
            button: BTN
            matchrule: MATCH_RULE
        callback= yield superagent.post(reqStr, Params)
        val= JSON.parse callback.text
        console.log val
    DMenu: (MENUID)->
        reqStr= "#{@host}/cgi-bin/menu/delconditional?access_token=#{@access_token}"
        Params=
            menuid: MENUID
        callback= yield superagent.post(reqStr, Params)
        val= JSON.parse callback.text
        console.log val
    QMenu: (OPENID_OR_WECHAT)->
        reqStr= "#{@host}/cgi-bin/menu/trymatch?access_token=#{@access_token}"
        Params=
            user_id: OPENID_OR_WECHAT
        callback= yield superagent.post(reqStr, Params)
        val= callback.text
        console.log val
    
    CInitMenu: (BTN)->
        reqStr= "#{@host}/cgi-bin/menu/create?access_token=#{@access_token}"
        Params=
            button: BTN
        callback= yield superagent.post(reqStr, Params)
        val= JSON.parse callback.text
        console.log val

    QAllMenu: ()->
        reqStr= "#{@host}/cgi-bin/menu/get?access_token=#{@access_token}"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text
        console.log val

    DInitMenu: ()->
        reqStr= "#{@host}/cgi-bin/menu/delete?access_token=#{@access_token}"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text
        return {
            code: val.errcode
            msg:  val.errmsg
        }
    QCode: (SCOPE, REURI)->
        reqStr= "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{@appid}&redirect_uri=#{REURI}&response_type=code&scope=#{SCOPE}&state=STATE#wechat_redirect"
        yield return reqStr
    QWebAccess_Info: (CODE)->
        reqStr= "#{@host}/sns/oauth2/access_token?appid=#{@appid}&secret=#{@appsecret}&code=#{CODE}&grant_type=authorization_code"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text
        return val
    QWeb_Re_Access_token: (REFRESH_TOKEN)->
        reqStr= "#{@host}/sns/oauth2/refresh_token?appid=#{@appid}&grant_type=refresh_token&refresh_token=#{REFRESH_TOKEN}"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text
        return val.access_token
    QWeb_UserInfo: (WEB_ACCESS_TOKEN, OPENID)->
        reqStr= "#{@host}/sns/userinfo?access_token=#{WEB_ACCESS_TOKEN}&openid=#{OPENID}&lang=zh_CN"
        callback= yield superagent.get(reqStr)
        val= JSON.parse callback.text
        return val

    # jsapi
    QTicket: ()->
        # 先查询数据库，没有结果再查询
        keyObj= yield serverinfo.findOne { name: 'ticket', is_expires: false }
        unless keyObj?
            reqStr= "#{@host}/cgi-bin/ticket/getticket?access_token=#{@access_token}&type=jsapi"
            callback= yield superagent.get(reqStr)
            val= JSON.parse callback.text

            jsapi_ticket= val.ticket
            expires_in= val.expires_in

            # save
            startTime= new Date().getTime()
            obj=
                name: 'ticket', jsapi_ticket: jsapi_ticket, expires_in: expires_in, startTime: startTime, is_expires: false
            yield serverinfo.insert obj
            return val.ticket
        else
            # 判断查询结果是否过期失效，是则更新状态，重新调用当前函数
            jsapi_ticket= yield $.isTicketExpired(keyObj.jsapi_ticket)
            if typeof jsapi_ticket isnt 'string'
                yield sut.DInitSut()
                return yield @QTicket()
            return jsapi_ticket

    QSignature: (URL, NONCESTR, TIMESTAMP)->
        args=
            jsapi_ticket: @jsapi_ticket
            noncestr: NONCESTR
            timestamp: TIMESTAMP
            url: URL
        sha1str= $.getSHA1String(args)
        yield return sha1str
    QUniSignature: (ARGS)->
        md5str= $.getMD5String(ARGS, @paysecret)
        yield return md5str
    QNewSignature: (ARGS)->
        md5str= $.getRawMD5String(ARGS, @paysecret)
        yield return md5str
    CUnifiedXml: (OPENID, PRODUCT)->
        args=
            appid: @appid
            attach: PRODUCT.seriesNo
            mch_id: @mch_id
            device_info: 'WEB'
            nonce_str: $.getNonceStr()
            body: PRODUCT.brandName
            notify_url: 'http://sut.alichs.com/purchase/unicallback'
            trade_type: 'JSAPI'
            out_trade_no: PRODUCT.tradeNum
            spbill_create_ip: PRODUCT.clientIP
            total_fee: $.fix2(100* PRODUCT.type_sum)
            openid: OPENID
        args.sign= yield @QUniSignature(args)
        unifiedXml= $.getUnifiedXml(args)
        return unifiedXml
    CHDUnifiedXml: ()->
        args=
            appid: 'wx45325d915de45e32'
            attach: '11111'
            mch_id: '10016498'
            device_info: 'WEB'
            nonce_str: $.getNonceStr()
            body: '222222'
            notify_url: 'http://sut.alichs.com/purchase/unicallback'
            trade_type: 'MWEB'
            out_trade_no: '333333'
            spbill_create_ip: '10.1.1.111'
            total_fee: $.fix2(1)
        args.sign= yield @QUniSignature(args)
        unifiedXml= $.getUnifiedXml(args)
        return unifiedXml
    CUnifiedorder: (XML)->
        reqStr= 'https://api.mch.weixin.qq.com/pay/unifiedorder'
        request= require 'request'
        Params=
            url: reqStr
            body: XML
            headers: {'Content-Type': 'text/xml'}

        return (done)-> request.post Params, done
    GParseXml: (XML)->
        callback= yield $.getParsedXML XML
        return callback.xml

    GClientIP: (REQUEST)->
        yield return REQUEST.headers['x-forwarded-for'] ||
        REQUEST.connection.remoteAddress ||
        REQUEST.socket.remoteAddress ||
        REQUEST.connection.socket.remoteAddress

    # Message
    GTokenValidation: (REQUEST)->
        url= require 'url'
        crypto= require 'crypto'
        query= url.parse(REQUEST, true).query
        signature = query.signature
        echostr = query.echostr
        msg_token= @msg_token
        timestamp = query.timestamp
        nonce = query.nonce
        s= [msg_token, timestamp, nonce].sort()
                                    .join('')
        scyptoString= crypto.createHash 'sha1'
                            .update s
                            .digest 'hex'
        result=
            scyptoString: scyptoString
            echostr: echostr
            signature: signature
        yield return result

    # Cservice
    GCustomService: ()->
        console.log @access_token, 'timeout after 7200s'
        reqStr= "#{@host}/cgi-bin/customservice/getkflist?access_token=#{@access_token}"
        console.log reqStr
        callback= yield superagent.get reqStr
        result= JSON.parse callback.text
        result= result.kf_list
        console.log result

        return result

    GCustomOnline: ()->
        reqStr= "#{@host}/cgi-bin/customservice/getonlinekflist?access_token=#{@access_token}"
        callback= yield superagent.get reqStr
        result= JSON.parse callback.text
        result= result.kf_online_list
        console.log result

        return result

    # Unavailable API
    CKfAccount: (ACCOUNTID, NICKNAME)->
        reqStr= "#{@host}/cgi-bin/customservice/kfaccount/add?access_token=#{@access_token}"
        Params=
            kf_account: "kf#{ACCOUNTID}@#{@wpID}"
            nickname: "#{NICKNAME}"
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            0: '客服添加成功'
            40066: 'API不可用'
            65400: 'API不可用'
            65403: '客服昵称不合法'
            65404: '客服帐号不合法'
            65405: '帐号数目已达到上限，不能继续添加'
            65406: '已经存在的客服帐号'

        return RETURN_CODE[val.errcode]

    CKfWechat: (ACCOUNTID, WXCODE)->
        reqStr= "#{@host}/customservice/kfaccount/inviteworker?access_token=#{@access_token}"
        Params=
            kf_account: "kf#{ACCOUNTID}@#{@wpID}"
            invite_wx: "#{WXCODE}"
        console.log Params
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            0: '成功'
            65400: 'API不可用，即没有开通/升级到新版客服'
            65401: '无效客服帐号'
            65407: '邀请对象已经是本公众号客服'
            65408: '本公众号已发送邀请给该微信号'
            65409: '无效的微信号'
            65410: '邀请对象绑定公众号客服数量达到上限（目前每个微信号最多可以绑定5个公众号客服帐号）'
            65411: '该帐号已经有一个等待确认的邀请，不能重复邀请'
            65412: '该帐号已经绑定微信号，不能进行邀请'

        return RETURN_CODE[val.errcode]
    GKfSession: (OPENID)->
        reqStr= "#{@host}/customservice/kfsession/getsession?access_token=#{@access_token}&openid=#{OPENID}"
        callback= yield superagent.get reqStr
        val= JSON.parse callback.text
        RETURN_CODE=
            0: val.kf_account
            65400: 'API不可用，即没有开通/升级到新版客服功能'
            40003: '非法的openid'

        return {
            code: val.errcode?=0
            result: RETURN_CODE[val.errcode?=0]
        }

    DKfSession: (ACCOUNTID, OPENID)->
        reqStr= "#{@host}/customservice/kfsession/close?access_token=#{@access_token}"
        Params=
            kf_account: ACCOUNTID
            openid: "#{OPENID}"
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            0: '成功'
            65400: 'API不可用，即没有开通/升级到新版客服功能'
            65401: '无效的客服帐号'
            65402: '帐号尚未绑定微信号，不能投入使用'
            65413: '不存在对应用户的会话信息'
            65414: '客户正在被其他客服接待'
            40003: '非法的openid'

        return {
            code: val.errcode
            result: RETURN_CODE[val.errcode]
        }

    # Mass Send Managerment
    MSendPreviewText: (OPENID, CONTENT)->
        reqStr= "#{@host}/cgi-bin/message/mass/preview?access_token=#{@access_token}"
        Params=
            touser: OPENID
            text:
                content: CONTENT
            msgtype: 'text'
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        console.log val, OPENID

        return {
            code: val.errcode
            text: val.errmsg
        }
    # Mass Send All
    MSendAllText: (CONTENT, TAGID)->
        reqStr= "#{@host}/cgi-bin/message/mass/sendall?access_token=#{@access_token}"
        if TAGID?
            Params=
                filter: {
                    is_to_all: false
                    tag_id: TAGID
                }
                text: { content: CONTENT }
                msgtype: 'text'
        else
            Params=
                filter: {
                    is_to_all: false
                    tag_id: 112
                }
                text: { content: CONTENT }
                msgtype: 'text'
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text
        console.log val

        return {
            code: val.errcode
            msg: val.errmsg
        }
    # MSendbyTag: ( )

    # User Tag Managerment
    UUserTagByOpenID: (OPENID, TAGID)->
        reqStr= "#{@host}/cgi-bin/tags/members/batchuntagging?access_token=#{@access_token}"
        Params=
            openid_list: [ OPENID ]
            tagid: TAGID
        callback= yield superagent.post reqStr, Params
        { errcode }= JSON.parse callback.text
        RETURN_CODE=
            '-1': '系统繁忙'
            40032: '每次传入的openid列表个数不能超过50个'
            45159: '非法的标签'
            40003: '传入非法的openid'
            49003: '传入的openid不属于此AppID'
        return RETURN_CODE[errcode]?= "标签取消成功"

    GUserTagByOpenID: (OPENID)->
        reqStr= "#{@host}/cgi-bin/tags/getidlist?access_token=#{@access_token}"
        Params=
            openid: OPENID
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text
        result= val.tagid_list

        RETURN_CODE=
            '-1': '系统繁忙'
            40003: '传入非法的openid'
            49003: '传入的openid不属于此AppID'

        return result

    CUserTag: (TAGNAME)->
        reqStr= "#{@host}/cgi-bin/tags/create?access_token=#{@access_token}"
        Params=
            tag: { name: "#{TAGNAME}" }
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            '-1': '系统繁忙'
            45157: '标签名非法，请注意不能和其他标签重名'
            45158: ' 标签名长度超过30个字节'
            45056: ' 创建的标签数过多，请注意不能超过100个 '

        return RETURN_CODE[val.errcode]?= "#{TAGNAME} 创建成功"
    GUserTag: ()->
        reqStr= "#{@host}/cgi-bin/tags/get?access_token=#{@access_token}"
        callback= yield superagent.get reqStr
        result= JSON.parse callback.text
        result= result.tags

        return result

    UUserTag: (TAGID, TAGNAME)->
        reqStr= "#{@host}/cgi-bin/tags/update?access_token=#{@access_token}"
        Params=
            tag:
                id: "#{TAGID}"
                name: "#{TAGNAME}"
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            '-1': '系统繁忙'
            45157: '标签名非法，请注意不能和其他标签重名'
            45158: '标签名长度超过30个字节'
            45058: '不能修改0/1/2这三个系统默认保留的标签'

        return RETURN_CODE[val.errcode]?= "标签#{TAGID} 修改成功"

    DUserTag: (TAGID)->
        reqStr= "#{@host}/cgi-bin/tags/delete?access_token=#{@access_token}"
        Params=
            tag: { id: "#{TAGID}" }
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            '-1': '系统繁忙'
            45058: '不能修改0/1/2这三个系统默认保留的标签'
            45057: '该标签下粉丝数超过10w，不允许直接删除'

        return RETURN_CODE[val.errcode]?= "标签#{TAGID} 删除成功"

    SFansTag: (OPENID, TAGID)->
        reqStr= "#{@host}/cgi-bin/tags/members/batchtagging?access_token=#{@access_token}"
        Params=
            openid_list: [ OPENID ]
            tagid: TAGID
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text

        RETURN_CODE=
            '-1': '系统繁忙'
            40032: '每次传入的openid列表个数不能超过50个'
            45159: '非法的标签'
            45059: '有粉丝身上的标签数已经超过限制'
            40003: '传入非法的openid'
            49003: '传入的openid不属于此AppID'

        return RETURN_CODE[val.errcode]?= "标签设置成功"

    GFansTag: (TAGID)->
        reqStr= "#{@host}/cgi-bin/user/tag/get?access_token=#{@access_token}"
        Params=
            tagid: "#{TAGID}"
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text
        unless val.count then result= val.count
        else result= val.data.openid

        RETURN_CODE=
            '-1': '系统繁忙'
            40003: '传入非法的openid'
            45159: '非法的tag_id'

        return RETURN_CODE[val.errcode]?= result

    GParseGeo: (COORD)->
        reqStr= "http://apis.map.qq.com/ws/geocoder/v1/?location=#{COORD}&key=#{@qqkey}&coord_type=1&get_poi=1&poi_options=radius=0"
        callback= yield superagent.get reqStr
        val= JSON.parse callback.text
        console.log '========', val.result.formatted_addresses.recommend, '=======', val.result.address
        return {
            street: val.result.address
            detail: val.result.formatted_addresses.recommend
            pois: val.result.pois
        }

    # Get Png callback
    GParseGeoMap: (COORD)->
        reqStr= "http://apis.map.qq.com/ws/staticmap/v2/?center=#{COORD}&zoom=10&size=600*300&maptype=roadmap&markers=size:large|color:0xFFCCFF|label:k|#{COORD}&key=#{@qqkey}"
        console.log reqStr
        callback= yield superagent.get reqStr
        console.log callback.body

    # template message
    GTemplateMsg: (OPENID, DATA, TYPE)->
        reqStr= "#{@host}/cgi-bin/message/template/send?access_token=#{@access_token}"
        Params=
            touser: OPENID
            template_id: INFOTEMPLATE[TYPE]
            url: 'http://weixin.qq.com/download'
            data: DATA
        callback= yield superagent.post reqStr, Params
        val= JSON.parse callback.text
        return val.errmsg?= 'check access_token'
    # rename User
    UUserRemark: (OPENID, REMARK)->
        reqStr= "#{@host}/cgi-bin/user/info/updateremark?access_token=#{@access_token}"
        Params=
            openid: OPENID
            remark: REMARK
            
        keyObj= yield userinfo.findOne { remark: REMARK }
        console.log keyObj, '===='
        unless keyObj? and keyObj.openid is OPENID
            callback= yield superagent.post reqStr, Params
            val= JSON.parse callback.text

        CODE= if val? then val.errcode else '-1'
        RETURN_CODE=
            '-1': "昵称[ #{REMARK} ]已被占用"
            0: "你不是之前的你，你是[ #{REMARK} ]"
            40013: 'APPID无效'
        return {
            code: CODE
            msg: RETURN_CODE[CODE] 
        }
    UAreaInfo: ()->
        result= yield gov.GArea
        return result

    StoreArea: (DATALIST)->
        result= yield gov.XlsxArea DATALIST
        return result

    Async: (CALLBACK)-> process.nextTick -> co -> yield CALLBACK

    Wait: (TIME, CALLBACK)->
        setTimeout ->
            co -> yield CALLBACK
        , TIME

    QWeather: (ADCODE)->
        reqStr= "#{@amaphost}/weather/weatherInfo?key=#{@amapkey}&city=#{ADCODE}"
        callback= yield superagent.get reqStr
        result= JSON.parse callback.text
        return result.lives[0]

    QAdcode: (ADNAME)->
        reqStr= "#{@amaphost}/config/district?key=#{@amapkey}&keywords=#{ADNAME}&level=city&subdistrict=0&extensions=base"
        callback= yield superagent.get reqStr
        val= JSON.parse callback.text
        result= val.districts[0]?.adcode
        return result?= '没有相关信息'

    GGps: (COORD)->
        reqStr= "#{@amaphost}/assistant/coordinate/convert?locations=#{COORD}&coordsys=gps&output=json&key=#{@amapkey}"
        callback= yield superagent.get reqStr
        val= JSON.parse callback.text
        result= val.locations
        return result?= '地址解析有误'
    GAmapGeo: (COORD)->
        reqStr= "#{@amaphost}/geocode/regeo?key=#{@amapkey}&location=#{COORD}&radius=50&extensions=all&batch=false&roadlevel=1"
        callback= yield superagent.get reqStr
        val= JSON.parse callback.text
        console.log '========', val.regeocode.formatted_address, '=======', val.regeocode.addressComponent.streetNumber.street
        return {
            address: val.regeocode.formatted_address
            adcode: val.regeocode.addressComponent.adcode
            street: val.regeocode.addressComponent.streetNumber
            pois: val.regeocode.pois
        }
    # robot
    GRobotMsg: (REMARK, INFO)->
        reqStr= "#{@rbhost}/openapi/api"
        Params=
            key: @rbkey
            info: INFO
            userid: REMARK

        callback= yield superagent.post reqStr, Params
        result= JSON.parse callback.text
        # console.log result
        return result

    GDiffItems: (COUNT, LIST)->
        filterArray= []
        data= [0...COUNT].map (val)->
            index= val*Math.random()*10*LIST.length % LIST.length
            unless ~~index in filterArray
                filterArray.push ~~index
                return LIST[~~index]
        result= data.filter (val)-> val?

        if result.length < COUNT
            remainNum= COUNT- result.length
            remainList= LIST.filter (item)-> item not in result
            return result.concat @GDiffItems remainNum, remainList
        else
            return result
    GRandomNum: (LENGTH)->
        result= $.getrandomNum LENGTH
        return result
    GJudgeDoomsDay: (DAYNUM, TIME)->
        result= $.isDoomsday DAYNUM, TIME
        return result

    # Material
    GMeterialCount: ()->
        reqStr= "#{@host}/cgi-bin/material/get_materialcount?access_token=#{@access_token}"
        callback= yield superagent.get reqStr
        result= JSON.parse callback.text

        return result
    GMerterials: (TYPE, OFFSET, COUNT)->
        reqStr= "#{@host}/cgi-bin/material/batchget_material?access_token=#{@access_token}"

        result= []
        if COUNT< 20
            Params=
                type: TYPE
                offset: TYPE
                count: COUNT
            callback= yield superagent.post reqStr, Params
            val= JSON.parse callback.text
            result= val.item
        else
            OFFSET+= 20
            COUNT-= 20
            result.concat @GMerterials TYPE, OFFSET, COUNT
        return result




sut= Object.create SuT

module.exports= sut
