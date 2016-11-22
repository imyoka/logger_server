request= require 'superagent'
cheerio= require 'cheerio'
xlsx= require 'node-xlsx'
fs= require 'fs'

host= 'http://www.stats.gov.cn/tjsj/tjbz/xzqhdm/'

GArea= ->
    html= yield request.get host
    $ = cheerio.load html.text
    href= $('.center_list_contlist li a').attr('href')
    newLink= "#{host}#{href}"
    html= yield request.get newLink
    $ = cheerio.load html.text
    dataSet= $('.TRS_PreAppend').children('.MsoNormal')
    result= []
    for data in dataSet
        code= data.children[0].children[0].data
        name= data.children[1].children[0].data
        result.push [code, name.trim()]
    yield return result

# data backup
XlsxArea= (DATALIST)->
    buffer = xlsx.build [
        {
            name: new Date().toLocaleDateString()
            data: DATALIST
        }
    ]
    fs.writeFileSync "#{__dirname}/AreaCN.xlsx", buffer
    yield return "#{__dirname}/AreaCN.xlsx"

module.exports= {
    GArea
    XlsxArea
}
