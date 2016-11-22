co= require 'co'
superagent= require 'superagent'
monk= require 'monk'
wrap= require 'co-monk'
db= monk('localhost/chlib')
talklib= wrap db.get('talklib')
#====== interal modules =========
sut= require '../sut'
#================================

Robot=
    host: 'http://www.tuling123.com'
    ASK: (CONTENT)->
        reqStr= "#{@host}/openapi/api"
        Params=
            key: 'e35b6490af914ec8a116170985b47940'
            info: CONTENT
            userid: 'Tsher'

        callback= yield superagent.post reqStr, Params
        result= JSON.parse callback.text
        console.log "[ 机器人A ]#{result.code}", result.text?= '关于这个我还不是很清楚', '\n'
        keyObj= yield talklib.findOne { Q: CONTENT }
        unless keyObj? then yield talklib.insert { Q: CONTENT, A: result.text }
        else
            unless keyObj.Q is CONTENT and result.text in key.A
                key.A.push result.text
                yield talklib.insert { Q: CONTENT, A: result.text }

        if result.code is 100000
            sut.Wait 8000* Math.random(), => yield @ANSWER result.text
        else
            sut.Wait 10000* Math.random(), => yield @ANSWER '关于这个我还不是很清楚'
    ANSWER: (CONTENT)->
        reqStr= "#{@host}/openapi/api"
        Params=
            key: '2bc913d146004e69ab731cf96472fede'
            info: CONTENT
            userid: 'Meiva'

        callback= yield superagent.post reqStr, Params
        result= JSON.parse callback.text
        console.log '\t\t\t\t\t'+ result.text?= '关于这个我还不是很清楚', "[ 机器人B ]#{result.code}"+ '\n'
        keyObj= yield talklib.findOne { Q: CONTENT }
        unless keyObj? then yield talklib.insert { Q: CONTENT, A: result.text }
        else
            unless keyObj.Q is CONTENT and result.text in key.A
                key.A.push result.text
                yield talklib.insert { Q: CONTENT, A: result.text }
        if result.code is 100000
            sut.Wait 3000* Math.random(), => yield @ASK result.text
        else
            sut.Wait 1000, => yield @ASK '关于这个我还不是很清楚'

robot= Object.create Robot

module.exports= (CONTENT)-> yield robot.ASK CONTENT

