monk= require 'monk'
wrap= require 'co-monk'
db= monk('Alichs:tsh000000@localhost:27017/hundun')

# module
member= wrap db.get('member')
lecture= wrap db.get 'lecture'

module.exports= {
    member
    lecture
}
