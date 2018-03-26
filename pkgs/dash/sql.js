const fs = require('fs')

module.exports.queries = function(query) {
  var file = fs.readFileSync('./queries.sql', 'utf8')
  var records = file.trim().split(';')
  var queries = []

  records.forEach(function(record) {
    record = record.trim()
    if(record.length == 0) {
      return;
    }

    var query = {}

    // query.name
    var index = record.indexOf("\n")
    query.name = record.substr(0, index)

    record = record.substr(index + 1, record.length)

    // query.icon
    index = record.indexOf("\n")
    query.icon = record.substr(0, index)

    record = record.substr(index + 1, record.length)

    // query.params
    query.params = []
    if (!record.startsWith("SELECT") && !record.startsWith("WITH")) {
      index = record.indexOf("\n")
      query.params = record.substr(0, index).split(' ')

      record = record.substr(index + 1, record.length)
    }

    // query.sql
    query.sql = record
    queries.push(query)
  })

  return queries
}
