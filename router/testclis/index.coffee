co= require('co')
_ = require('lodash')
#====== interal modules =========
{
ME, MULTILINE,

KEFU, KEFU_CHATID, KEFU_ONLINE, 
KEFU_CREATE,KEFU_INVITE, KEFU_DELETE

MASS_SEND

CREATE_TAG, TAG_LIST, UPDATE_TAG
DELETE_TAG, TAGFAN_LIST 

LOCATE 

REDIS_IN, REDIS_OUT
TEMPLATE
REMARK
ACCEPTLINK, DELETELINK
USER_LIST

MENU, DELETE_MENU
ADD_AREA, IN_XLSX_AREA
REMOVE_USER_TAG, ADD_USER_TAG, USER_TAGLIST }= require './rules'
sut= require '../sut'
{ session }= require '../utils/session'
{ DinsertLocation, DqueryLocation, DqueryAllLocation }= require '../clis/location'
{ DinsertUserInfo, DqueryUserInfo, DqueryAllUserInfo, DupdateUserInfo }= require '../clis/userinfo'
{ DinsertUserAction, DqueryUserAction, DqueryAllUserAction, DupdateUserAction }= require '../clis/useraction'
{ DinsertAreaInfo, DinsertAllAreaInfo, DqueryAreaInfo, DqueryAllAreaInfo, DupdateAreaInfo }= require '../clis/areainfo'

learn= require '../selflearn'

tpl= """
<xml>
    <ToUserName><![CDATA[<%-toUsername%>]]></ToUserName>
    <FromUserName><![CDATA[<%-fromUsername%>]]></FromUserName>
    <CreateTime><%=createTime%></CreateTime>
    <MsgType><![CDATA[<%=msgType%>]]></MsgType>
    <% if (msgType === "news") { %>
        <ArticleCount><%=content.length%></ArticleCount>
        <Articles>
        <% content.forEach(function(item){ %>
            <item>
            <Title><![CDATA[<%-item.title%>]]></Title>
            <Description><![CDATA[<%-item.description%>]]></Description>
            <PicUrl><![CDATA[<%-item.picUrl || item.picurl || item.pic %>]]></PicUrl>
            <Url><![CDATA[<%-item.url%>]]></Url>
            </item>
        <% }); %>
        </Articles>
    <% } else if (msgType === "music") { %>
        <Music>
            <Title><![CDATA[<%-content.title%>]]></Title>
            <Description><![CDATA[<%-content.description%>]]></Description>
            <MusicUrl><![CDATA[<%-content.musicUrl || content.url %>]]></MusicUrl>
            <HQMusicUrl><![CDATA[<%-content.hqMusicUrl || content.hqUrl %>]]></HQMusicUrl>
        </Music>
    <% } else if (msgType === "voice") { %>
        <Voice>
            <MediaId><![CDATA[<%-content.mediaId%>]]></MediaId>
        </Voice>
    <% } else if (msgType === "image") { %>
        <Image>
            <MediaId><![CDATA[<%-content.mediaId%>]]></MediaId>
        </Image>
    <% } else if (msgType === "video") { %>
        <Video>
            <MediaId><![CDATA[<%-content.mediaId%>]]></MediaId>
            <Title><![CDATA[<%-content.title%>]]></Title>
            <Description><![CDATA[<%-content.description%>]]></Description>
        </Video>
    <% } else if (msgType === "transfer_customer_service") { %>
        <% if (content && content.kfAccount) { %>
            <TransInfo>
                <KfAccount><![CDATA[<%-content.kfAccount%>]]></KfAccount>
            </TransInfo>
        <% } %>
    <% } else { %>
        <Content><%-content%></Content>
    <% } %>
</xml>
"""

compiled= _.template tpl

getLink= (MSG)->
    { ToUserName, FromUserName, CreateTime, Content, MsgType }= MSG
    remark= yield session.hget "#{FromUserName}", 'remark'

    unless remark?
        { remark }= yield sut.QUserInfo FromUserName
        yield session.hset "#{FromUserName}", 'remark', remark
    info=
        msgType: 'text'
        content: Content
        createTime: new Date().getTime()
        toUsername: FromUserName
        fromUsername: ToUserName
    # if ACCEPTLINK.test Recognition
    waitUserOpenid  = yield session.hget "Link#{FromUserName}", 'waiting'
    accpetUserOpenid= yield session.hget "Link#{FromUserName}", 'accepted'
    if accpetUserOpenid? then ureAcceptedOpenid= yield session.hget "Link#{accpetUserOpenid}", 'accepted'
    console.log waitUserOpenid, '=====', accpetUserOpenid, '======', ureAcceptedOpenid
    if waitUserOpenid? and accpetUserOpenid? and waitUserOpenid is accpetUserOpenid and ureAcceptedOpenid is FromUserName
        if DELETELINK.test Content.trim()
            yield session.del "Link#{FromUserName}"
            yield session.del "Link#{accpetUserOpenid}"
            { remark }= yield sut.QUserInfo FromUserName
            data=
                first:
                    value: "[ #{remark} ]关闭了你们的虫洞"
                keyword1:
                    value: '切换信道中...'
                keyword2:
                    value: new Date().toLocaleTimeString()
                remark:
                    value: ''
            result= yield sut.GTemplateMsg accpetUserOpenid, data, 'BUSSINESS'
            if result is 'ok' then info.content= '虫洞关闭成功' else info.content= '虫洞关闭失败'
        else if LOCATE.test Content.trim()
            len= yield session.zcard "LOCATION#{accpetUserOpenid}"
            data= yield session.zrange "LOCATION#{accpetUserOpenid}", len-1, len
            lcinfo= yield DqueryLocation [{ openid: accpetUserOpenid}]
            { remark }= yield sut.QUserInfo accpetUserOpenid
            if data.length isnt 0
                { address, adcode, street, pois }= yield sut.GAmapGeo data.toString()
                time= new Date().toLocaleString()
                location= "\n[ #{address} ]\n正#{street.direction}方向#{street.distance}米处有#{street.street}#{street.number}"
                guideinfo= pois.map (poi)->
                    tel= unless poi.tel.length is 0 then ",可咨询:#{poi.tel}。" else '。'
                    return "[-] 目标地点的正#{poi.direction}方向#{poi.distance}米处有#{poi.name}#{tel}"
                .join '\n\r'

                # weather
                {
                    province, city, weather, temperature
                    winddirection, windpower, humidity
                    reporttime
                }= yield sut.QWeather adcode

                wtrInfo= """
                    [ #{weather} #{temperature}摄氏度 ]
                    [ #{winddirection}风 － #{windpower}级 ]
                    [ 湿度 － #{humidity}% ]
                """

                info.content= "[#{time}] #{location}\n\r#{guideinfo}\n\r#{wtrInfo}"
            else if lcinfo[0]?
                time= new Date(lcinfo[0].time* 1000).toLocaleString()
                location= lcinfo[0].info
                info.content= "[#{time}] #{location}"
            else
                info.content= '暂无位置信息'
        else
            yield session.expire "Link#{toOpenid}", 1000* 60* 30
            yield session.expire "Link#{FromUserName}", 1000* 60* 30
            # send toUser template message
            # { remark }= yield sut.QUserInfo FromUserName
            data=
                first:
                    value: "你有来自[ #{remark} ]的消息"
                keyword1:
                    value: Content.trim()
                    color: '#cc3300'
                keyword2:
                    value: new Date().toLocaleTimeString()
                remark:
                    value: ''
            result= yield sut.GTemplateMsg accpetUserOpenid, data, 'LINKMSG'
            if result is 'ok' then info.content= '留言成功' else info.content= '留言失败'
    else if waitUserOpenid?
        if DELETELINK.test Content.trim()
            yield session.del "Link#{FromUserName}"
            yield session.del "Link#{accpetUserOpenid}"
            info.content= '你已取消虫洞创建请求'
        # if toUser return abs, means accept, then connect!
        if ACCEPTLINK.test Content.trim()
            result= yield session.hset "Link#{FromUserName}", 'accepted', waitUserOpenid
            yield session.expire "Link#{FromUserName}", 1000* 60* 30
            if result is 1
                info.content= '虫洞创建成功'
                { remark }= yield sut.QUserInfo FromUserName
                data=
                    first:
                        value: "[ #{remark} ]响应了你的召唤，并打开了虫洞，开始对话吧"
                    keyword1:
                        value: '切换信道中...'
                    keyword2:
                        value: new Date().toLocaleTimeString()
                    remark:
                        value: ''
                result= yield sut.GTemplateMsg waitUserOpenid, data, 'BUSSINESS'
            else info.content= '对方等你太久，已另觅新欢'
    else
        # 与公众号发消息
        if ME.test Content.trim()
            keyObj= yield from DqueryUserInfo [{ openid: FromUserName }]
            if keyObj[0]? then info.content= "你是[ #{keyObj[0].remark} ]"
            else info.content= '你没有户口本，请联系管理员'
            # info.content= "\<a href=\'http://me.alichs.com:9999\'\>Nice\<\/a\>"
        else if DELETELINK.test Content.trim()
            info.content= '你已关闭虫洞'
        else if MULTILINE.test Content.trim()
            info.content= """
            Ich bin Alichs
            Ich liebe dich
            Du bist Meiva
            """
        else if KEFU.test Content.trim()
            kflist= yield sut.GCustomService()
            data= kflist.map (one)-> {
                    title: """
                        编号: #{one.kf_id}
                        昵称: #{one.kf_nick}
                    """
                    picurl: one.kf_headimgurl
                }
            # 插入列表头
            data.splice 0, 0, {
                title: '客服列表[全部]'
                description: '请输入客服编号，直接沟通'
            }
            info.msgType= 'news'
            info.content= data
        else if KEFU_CHATID.test Content.trim()
            info.msgType= 'transfer_customer_service'
            info.content= {
                kfAccount: "kf#{Content.trim()}@SuppeUndTagebuch"
            }
        else if KEFU_ONLINE.test Content.trim()
            kflist= yield sut.GCustomService()
            kf_online_list= yield sut.GCustomOnline()
            data= kf_online_list.map (detail)->
                one= kflist.filter (kf)-> kf.kf_id is detail.kf_id
                one= one.pop()
                return {
                    title: """
                        编号: #{one.kf_id}
                        昵称: #{one.kf_nick} 正接待#{detail.accepted_case}人
                    """
                    picurl: one.kf_headimgurl
                }
            # 插入列表头
            data.splice 0, 0, {
                title: '客服列表[在线]'
                description: '请输入客服编号，直接沟通'
            }
            info.msgType= 'news'
            info.content= data
        else if KEFU_CREATE.test Content.trim()
            data= Content.trim().match KEFU_CREATE
            id= data[1]
            name= data[2]
            info.content= yield sut.CKfAccount id, name
        else if KEFU_INVITE.test Content.trim()
            data= Content.trim().match KEFU_INVITE
            id= data[1]
            code= data[2]
            info.content= yield sut.CKfWechat id, code
        else if KEFU_DELETE.test Content.trim()
            data= Content.trim().match KEFU_DELETE
            id= data[1]
            openid= ToUserName
            info.content= yield sut.DKfSession(id, openid)
        else if MASS_SEND.test Content.trim()
            data= Content.trim().match MASS_SEND
            remark= data[1]
            content= if data[2].length is 0 then '你好' else data[2]
            switch remark
                when 'all'
                    sut.Async -> yield sut.MSendAllText content.trim()
                    info.content= '群发成功'
                    # { code, msg }= yield sut.MSendAllText content.trim()
                    # if code is 0 then info.content= '群发成功'
                    # else if code is 40152 then info.content= msg
                    # else info.content= "群发失败：[ #{code} ] - #{msg}"
                when 'some'
                    if ~~content> 0
                        sut.Async ->
                            # everyday message send Begin
                            # later will intergrate into sut lib
                            # get data from db
                            userlist= yield from DqueryAllUserInfo [{subscribe: 1}]
                            openidlist= userlist[0].map ({openid, remark, city, nickname, sex, province, country, headimgurl})-> 
                                return { 
                                    openid, 
                                    remark, 
                                    headimgurl 
                                    city, 
                                    nickname, 
                                    sex, 
                                    province, 
                                    country, 
                                }
                            # filter data from useraction
                            useractionlist= yield from DqueryAllUserAction [{}]
                            disturblist= useractionlist[0].filter((val)->
                                overday= sut.GJudgeDoomsDay 1, val.updatetime?= val.createtime
                                if val.MSendPreviewText> 0 and not overday
                                    return true
                                else
                                    return false
                            ).map ({openid})-> return openid

                            luckylist= openidlist.filter (val)-> val.openid not in disturblist and val.remark?

                            selectlist= sut.GDiffItems ~~content, luckylist

                            # ##@ Test  'oJL-IwEhKw0PX0wiABz5a2w74qBY', 
                            filterlist= selectlist.filter (val)-> val.openid not in ['oJL-IwJ9wPOsco-Qr-_bG5p1TeP4', 'oJL-IwPXNNBH_NEH7NESh6E27ua0']
                            console.log selectlist, filterlist
                            for val, i in filterlist
                                do (val)->
                                    chatBegin= ['冷笑话', val.city+'天气', '笑话', '故事']
                                    randomTitle= sut.GRandomNum chatBegin.length
                                    unless randomTitle is 1 and val.city? then randomTitle= 0
                                    chatText= chatBegin[randomTitle]
                                    sut.Wait (i+1+randomTitle)*2000, ->
                                        { code, text }= yield sut.GRobotMsg val.remark, chatText
                                        console.log "[ #{val.nickname} ] [ #{chatText} ]", text, val.openid
                                        
                                        { code, text }= yield sut.MSendPreviewText val.openid, text
                                        if code is 0
                                            console.log 'record in mongo'
                                            keyObj= yield from DqueryUserAction [{openid: val.openid}]
                                            unless keyObj[0]?
                                                insertObj= Object.assign val, {
                                                    MSendPreviewText: 1
                                                    createtime: new Date().getTime()
                                                    updatetime: new Date().getTime()
                                                }
                                                yield from DinsertUserAction [insertObj]
                                            else 
                                                updateObj= Object.assign keyObj[0], val, {
                                                    MSendPreviewText: keyObj[0].MSendPreviewText + 1
                                                    updatetime: new Date().getTime()
                                                }
                                                yield from DupdateUserAction [updateObj]

                                        else console.log text
                            # everyday message send End

                else
                    # get userinfo.openid from dbs by remark
                    # send MassPreviewText to userinfo.openid
                    # return info.content message to sender man： 沟通请求发送成功
                    # set redis [key]: [value] as [Link-userinfo.openid-]: 'abs'
                    keyObj= yield from DqueryUserInfo [{ remark: remark }]
                    console.log keyObj[0], 'out'
                    unless keyObj[0]? then info.content= '你要联系的对象变更了Remark或者离开了我们的世界'
                    else
                        toOpenid= keyObj[0].openid
                        isBusy= yield session.hget "Link#{toOpenid}", 'accepted'
                        console.log keyObj[0].openid, 'in', isBusy
                        unless isBusy? and isBusy isnt FromUserName
                            yield session.hset "Link#{toOpenid}", 'waiting', FromUserName
                            yield session.hset "Link#{FromUserName}", 'waiting', toOpenid
                            yield session.hset "Link#{FromUserName}", 'accepted', toOpenid
                            yield session.expire "Link#{toOpenid}", 1000* 60* 30
                            yield session.expire "Link#{FromUserName}", 1000* 60* 30
                            # { remark }= yield sut.QUserInfo FromUserName
                            yield sut.MSendPreviewText keyObj[0].openid, "[ #{remark} ]召唤你，并附加信息：#{ content }\n\r回复[ abs ]响应召唤。"
                            info.content= '沟通请求发送成功'
        else if CREATE_TAG.test Content.trim()
            data= Content.trim().match CREATE_TAG
            tagename= data[1]
            info.content= yield sut.CUserTag tagename
        else if TAG_LIST.test Content.trim()
            tags= yield sut.GUserTag()
            data= tags.map (tag)->
                return """
                    编号|<a>#{tag.id}</a> 标签名|<a>#{tag.name}</a> 粉丝数|<a>#{tag.count}</a>
                """
            info.content= data.join '\n'
        else if UPDATE_TAG.test Content.trim()
            data= Content.trim().match UPDATE_TAG
            id= data[1]
            name= data[2]
            info.content= yield sut.UUserTag(id, name)
        else if DELETE_TAG.test Content.trim()
            data= Content.trim().match DELETE_TAG
            id= data[1]
            info.content= yield sut.DUserTag id
        else if TAGFAN_LIST.test Content.trim()
            data= Content.trim().match TAGFAN_LIST
            id= data[1]
            openidlist= yield sut.GFansTag id
            unless openidlist is 0
                openidlist= openidlist.map (openid)-> return { openid }
                userinfoList= yield sut.QUserInfoList openidlist
                userList= userinfoList.map (userinfo)->
                    if userinfo.subscribe
                        return {
                            title: """
                                昵称: #{userinfo.remark}
                                微信名: #{userinfo.nickname}
                                性别: #{if userinfo.sex then '男' else '女'}
                            """
                            picurl: userinfo.headimgurl
                        }
                    else return null
                userList= userList.filter (user)-> return user isnt null
                # 插入列表头
                userList.splice 0, 0, {
                    title: "#{id}标签 － 用户列表"
                }
                info.msgType= 'news'
                info.content= userList
            else
                info.content= '无数据'
        else if LOCATE.test Content.trim()
            len= yield session.zcard "LOCATION#{FromUserName}"
            data= yield session.zrange "LOCATION#{FromUserName}", len-1, len
            lcinfo= yield DqueryLocation [{ openid: FromUserName}]
            if data.length isnt 0
                # { street, detail, pois } = yield sut.GParseGeo data.toString()
                # time= new Date().toLocaleString()
                # location= "在#{street}街道的#{detail}"
                # guideinfo= pois.map (poi)->
                #     direction= unless poi._dir_desc is '' then "#{poi._dir_desc}方向" else "正方向"
                #     return "[-] 目标地点在#{poi.title}#{direction}#{poi._distance}米"
                # .join '\n\r'
                # info.content= "[#{time}] #{location}\n\r #{guideinfo}"
                { address, adcode, street, pois }= yield sut.GAmapGeo data.toString()
                time= new Date().toLocaleString()
                location= "\n[ #{address} ]\n正#{street.direction}方向#{street.distance}米处有#{street.street}#{street.number}"
                guideinfo= pois.map (poi)->
                    tel= unless poi.tel.length is 0 then ",可咨询:#{poi.tel}。" else '。'
                    return "[-] 目标地点的正#{poi.direction}方向#{poi.distance}米处有#{poi.name}#{tel}"
                .join '\n\r'

                # weather
                {
                    province, city, weather, temperature
                    winddirection, windpower, humidity
                    reporttime
                }= yield sut.QWeather adcode

                wtrInfo= """
                    [ #{weather} #{temperature}摄氏度 ]
                    [ #{winddirection}风 － #{windpower}级 ]
                    [ 湿度 － #{humidity}% ]
                """

                info.content= "[#{time}] #{location}\n\r#{guideinfo}\n\r#{wtrInfo}"
            else if lcinfo[0]?
                time= new Date(lcinfo[0].time* 1000).toLocaleString()
                location= lcinfo[0].info
                info.content= "[#{time}] #{location}"
            else
                info.content= '暂无位置信息'
        else if REDIS_IN.test Content.trim()
            data= Content.trim().match REDIS_IN
            key= data[1]
            val= data[2]
            yield session.zadd "LOCATION#{FromUserName}", CreateTime, val
            len= yield session.zcard "LOCATION#{FromUserName}"
            console.log len
            if len> 24
                yield session.del "LOCATION#{FromUserName}"
                console.log 'delete success'
            else
                console.log yield session.zrange "LOCATION#{FromUserName}", len-1, len
                console.log 'add success'
        else if TEMPLATE.test Content.trim()
            data=
                first:
                    value: 'first'
                    color: '#ffccff'
                keyword1:
                    value: 'keynote1'
                keyword2:
                    value: 'keynote2'
                remark:
                    value: 'remark'
            info.content= yield sut.GTemplateMsg FromUserName, data
        else if REMARK.test Content.trim()
            data= Content.trim().match REMARK
            remark= data[1]
            { code, msg }= yield sut.UUserRemark FromUserName, remark
            info.content= msg

            # store openid linked with remark, 
            # check dbs:
            #   if the relationship not exist then insert
            #   if remark outdated then update
            orInfo=
                openid: FromUserName
                remark: remark
                createtime: new Date().getTime()
                updatetime: new Date().getTime()
            if ~~code in [-1, 0]
                keyObj= yield from DqueryUserInfo [{ openid: FromUserName }]
                unless keyObj[0]? then yield from DinsertUserInfo [orInfo]
                else
                    if keyObj[0].remark is remark then info.content= '你就是你，不需要改变'
                    else
                        keyObj[0].remark= remark
                        yield from DupdateUserInfo [keyObj[0]]
            else
                info.content= msg
        else if USER_LIST.test Content.trim()
            userlist= yield from DqueryAllUserInfo [{}]
            dataStr= userlist[0].filter( (val)-> return val.remark isnt '' ).map (info)->
                return """
                    [ #{info.remark} ] <a href='#{ info.headimgurl }'>#{ info.nickname}</a>
                """
            info.content= dataStr.splice(0, 10).join '\n\r'
            sut.Async ->
                data= userlist[0].map (val)-> return { openid: val.openid }
                userinfoList= yield sut.QUserInfoList data
                yield from DupdateUserInfo userlist[0].map ({ openid, _id })->
                    result= userinfoList.filter( (val)-> return val.openid is openid ).map (info, i)->
                        info._id= _id
                        return info
                    return result[0]
        else if MENU.test Content.trim()
            data= Content.trim().match MENU
            key= data[1]
            type= data[2]
            if type is 'dev'
                btn= [
                    {
                        "type":"click"
                        "name":"汤"
                        "key":"SHUTDOWN_ALL_LINK" 
                    },
                    {
                        "name":"日记"
                        "sub_button":[
                            {
                                "type":"click"
                                "name":"幸运商店"
                                "key":"RANDOM_SHOPS"
                            },
                            {
                                "type":"click"
                                "name":"幸运商品"
                                "key":"RANDOM_GOODS"
                            },
                            {
                                "type":"view"
                                "name":"购物车"
                                "url":"http://sut.alichs.com/cart"
                            },
                            {
                                "type":"click"
                                "name":"文字坐标"
                                "key":"LINK_LOCATION"
                            },
                            {
                                "type":"click"
                                "name":"操作手册"
                                "key":"ABOUT_THIS"
                            }
                        ]
                    }
                ]
            else
                btn= [
                    {
                        "type":"click"
                        "name":"汤"
                        "key":"SHUTDOWN_ALL_LINK" 
                    },
                    {
                        "type":"click"
                        "name":"文字坐标"
                        "key":"LINK_LOCATION"
                    }
                ]
            yield sut.DInitMenu()
            yield sut.CInitMenu(btn)
            yield sut.QAllMenu()
        else if DELETE_MENU.test Content.trim()
            { code, msg }= yield sut.DInitMenu()
            if code is 0 then info.content= '菜单删除成功！'
            else info.content= msg
        else if /^shops$/i.test Content.trim()
            info.content= "\<a href=\'http://sut.alichs.com/shop\'\>卖汤啦\<\/a\>"
        else if /^udgov$/i.test Content.trim()
            data= yield sut.UAreaInfo
            lists= data.map (val)-> {
                code: val[0]
                name: val[1]
            }
            # mass tasks
            info.content= '更新请求已发送，等待通知消息'
            sut.Async ->
                callback= yield from DinsertAllAreaInfo lists
        else if /^[^0|9]\d{16}[\d|x]|[^0|9]\d{5}$/i.test Content.trim()
            data= Content.trim().match /^(\d{6})(\d{8})(\d{3}).?$/
            if data?
                province= data[1].split('').fill(0, 2).join('')
                city= data[1].split('').fill(0, 4).join('')
                village= data[1]
                birth= "#{data[2].substr(0, 4)}年#{data[2].substr(4, 2)}月#{data[2].substr(-2, 2)}日"
                sex= if ~~data[3]%2 is 0 then '女' else '男'
                areaname= yield from DqueryAreaInfo [{code: province}, {code: city}, {code: village}]
                console.log areaname
                info.content=  "[ #{areaname[0].name}#{areaname[1].name}#{areaname[2].name} ]\n[ #{birth} ] [ #{sex} ]"
            else
                province= Content.trim().split('').fill(0, 2).join('')
                city= Content.trim().split('').fill(0, 4).join('')
                village= Content.trim()
                areaname= yield from DqueryAreaInfo [{code: province}, {code: city}, {code: village}]
                console.log areaname, city, village
                info.content= "[ #{areaname[0].name}#{areaname[1].name}#{areaname[2].name} ]"
        else if ADD_AREA.test Content.trim()
            data= Content.trim().match ADD_AREA
            code= data[1]
            name= data[2]
            keyObj= yield from DqueryAreaInfo [{code: code}]
            unless keyObj[0]? then result= yield from DinsertAreaInfo [{code: code, name: name}]
            else
                keyObj[0].name= name
                result= yield from DupdateAreaInfo [keyObj[0]]
            info.content= '地区代码更新完成'
        else if IN_XLSX_AREA.test Content.trim()
            # standard async backup
            info.content= '数据备份请求已发出，等待通知消息'
            sut.Async ->
                data= yield from DqueryAllAreaInfo [{}]
                if data[0]?
                    result= data[0]
                    datalist= result.map (val)-> [val.code, val.name]
                    filePath= yield sut.StoreArea datalist
                    msg=
                        first:
                            value: "数据备份完毕"
                        keyword1:
                            value: "备份文件路径：#{filePath}"
                        keyword2:
                            value: new Date().toLocaleTimeString()
                        remark:
                            value: ''
                    yield sut.GTemplateMsg FromUserName, msg, 'BUSSINESS'
        else if /^asy$/i.test Content.trim()
            sut.Async ->
                data= yield from DqueryAllAreaInfo [{}]
                console.log data[0].length
        else if /^wtr\s+(.*)$/i.test Content.trim()
            data= Content.trim().match /^wtr\s+(.*)$/i
            name= encodeURIComponent data[1]
            adcode= yield sut.QAdcode name
            {
                province, city, weather, temperature
                winddirection, windpower, humidity
                reporttime
            }= yield sut.QWeather adcode

            info.content= """
                [ #{province}#{city} ]
                [ #{weather} #{temperature}摄氏度 ]
                [ #{winddirection}风 － #{windpower}级 ]
                [ 湿度 － #{humidity}% ]
                [ #{reporttime} ]
            """
        else if /^mc$/i.test Content.trim()
            { news_count }= yield sut.GMeterialCount()
            result= yield sut.GMerterials 'news', 0, news_count
            data= result.map ({media_id, content, update_time})->
                { title, author, digest, url, thumb_url }= content.news_item[0]
                return {
                    title: "#{title} - By #{author}"
                    description: digest
                    picurl: thumb_url
                    url: url
                }
            info.msgType= 'news'
            info.content= data
        else if /^pd$/i.test Content.trim()
            info.content= "\<a href=\'http://sut.alichs.com/productM\'\>商品管理\<\/a\>"
        else if REMOVE_USER_TAG.test Content.trim()
            data= Content.trim().match REMOVE_USER_TAG
            remark= data[1]
            tagid= data[2]
            keyObj= yield from DqueryUserInfo [{ remark: remark }]
            if keyObj[0]?
                { openid }= keyObj[0]
                info.content= yield sut.UUserTagByOpenID openid, tagid
            else
                info.content= "#{remark}或已取消关注,获取openid失败"
        else if ADD_USER_TAG.test Content.trim()
            data= Content.trim().match ADD_USER_TAG
            remark= data[1]
            tagid= data[2]
            keyObj= yield from DqueryUserInfo [{ remark: remark }]
            console.log keyObj[0]
            if keyObj[0]?
                { openid }= keyObj[0]
                info.content= yield sut.SFansTag openid, tagid
            else
                info.content= "#{remark}或已取消关注,获取openid失败"
        else if USER_TAGLIST.test Content.trim()
            data= Content.trim().match USER_TAGLIST
            remark= data[1]
            keyObj= yield from DqueryUserInfo [{ remark: remark }]
            if keyObj[0]?
                { openid }= keyObj[0]
                tagidlist= yield sut.GUserTagByOpenID openid
                info.content= "#{remark} - #{tagidlist.join(',')}"
            else
                info.content= "#{remark}或已取消关注,获取openid失败"
        else if /^hd$/i.test Content.trim()
            unifiedXml= yield sut.CHDUnifiedXml()
            result= yield sut.CUnifiedorder unifiedXml
            console.log '==========', result
        else if /^ds\s+(.*)$/i.test Content.trim()
            yield session.select '15'
            data= Content.trim().match /^ds\s+(.*)$/i
            rewarditem=
                action_id: ~~(Math.random()*100)
                user_name: FromUserName
                comment: '讲得好，必须赞'
                action_time: new Date().toLocaleString()
            yield session.publish 'rewardlist', JSON.stringify rewarditem
        else
            # { remark }= yield sut.QUserInfo FromUserName
            console.log remark
            { code, text, url, list }= yield sut.GRobotMsg remark, Content.trim()
            if code is 100000
                info.content= text
                sut.Async ->yield from learn text
            else if code is 200000 then info.content= "\<a href=\'#{url}\'\>#{text}\<\/a\>"
            else if code is 302000 then info.content= "#{text}，但是不要这么八卦。"
            else if code is 308000
                count= if list.length < 8 then list.length else 8
                menuList= list.splice(0, count).map (menu)->
                    return {
                        title: menu.info
                        picurl: menu.icon
                        url: menu.detailurl
                    }
                # 插入列表头
                menuList.splice 0, 0, {
                    title: text
                }
                info.msgType= 'news'
                info.content= menuList
            else
                info.content= text
    reply= compiled info
    yield return reply

getPicandText= (MSG)->
    { ToUserName, FromUserName, Content, MsgType }= MSG
    info= {}

getVoice= (MSG)->
    { ToUserName, FromUserName, MsgType, MediaId, Format, Recognition }= MSG
    remark= yield session.hget "#{FromUserName}", 'remark'
    unless remark?
        { remark }= yield sut.QUserInfo FromUserName
        yield session.hset "#{FromUserName}", 'remark', remark
    info=
        msgType: 'text'
        createTime: new Date().getTime()
        toUsername: FromUserName
        fromUsername: ToUserName
        content: ''
    # { remark }= yield sut.QUserInfo FromUserName
    { code, text, url, list }= yield sut.GRobotMsg remark, Recognition
    if code is 100000
        info.content= text
        sut.Async -> yield from learn text
    else if code is 200000 then info.content= "\<a href=\'#{url}\'\>#{text}\<\/a\>"
    else if code is 302000 then info.content= "#{text}，但是不要这么八卦。"
    else if code is 308000
        count= if list.length < 8 then list.length else 8
        menuList= list.splice(0, count).map (menu)->
            return {
                title: menu.info
                picurl: menu.icon
                url: menu.detailurl
            }
        # 插入列表头
        menuList.splice 0, 0, {
            title: text
        }
        info.msgType= 'news'
        info.content= menuList
    else
        info.content= "你说[ #{Recognition} ]"
        sut.Async -> yield from learn Recognition
    reply= compiled info
    yield return reply
 
getImage= (MSG)->
    { ToUserName, FromUserName, MsgType, MediaId, PicUrl }= MSG
    info=
        msgType: 'image'
        createTime: new Date().getTime()
        toUsername: FromUserName
        fromUsername: ToUserName
        content:
            mediaId: MediaId

    reply= compiled info
    yield return reply


module.exports= {
    getLink
    getVoice
    getImage
}