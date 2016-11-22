monk= require 'monk'
wrap= require 'co-monk'
db= monk('localhost/hundun')

# module
member= wrap db.get('member')

module.exports= {
    member
}