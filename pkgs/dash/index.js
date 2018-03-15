const db = require('./db.js');
const engine = require('./engine.js');
const sql = require('./sql.js');

engine.get('/dash', (request, response) => {
  response.render('dash', {
    task_groups: db.dash()
  })
})

sql.queries().forEach(function(query) {
  console.log("Loading route for /" + query.name)

  engine.get('/' + query.name, (request, response) => {
    var params = []
    query.params.forEach(function(param_name) {
      params.push(request.param(param_name))
    })

    var columns = []
    query.columns.forEach(function(column) {
      var oColumn = {}
      oColumn.index = column
      oColumn.title = column
      oColumn.type = 'string'
      oColumn.flex = 1

      columns.push(oColumn)
    })

    query.resolved_sql = query.sql.replace(/(\{\d+\})/g, function (param){
      return params[+(param.substr(1, param.length - 2))||0]
    })

    db.query(query.resolved_sql).then((result) => {
      response.render('query', {
        data: result,
        name: query.name,
        columns: columns
      })
    }).catch((err) => {
      console.log('Error!', err)
    })
  })
})

engine.listen()
