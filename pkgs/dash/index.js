const db = require('./db.js');
const engine = require('./engine.js');
const sql = require('./sql.js');

engine.get('/dash', (request, response) => {
  response.render('dash', {
    task_groups: db.dash(),
    nav_bar: query_nav_bar(queries, 'dash')
  })
})

function query_nav_bar(queries, current_query) {
  var dActive = ""
  if ('dash' == current_query) {
    dActive = 'class="active" '
  }
  var nav_bar = '<a ' + dActive + ' href="dash"><i class="fa fa-tachometer-alt"></i><br />dash</a>'
  queries.forEach(function(query) {
    var post_data = ""
    if (query.params.length != 0) {
      var dval = 7
      post_data = "?"
      query.params.forEach(function(param_name) {
        post_data += param_name + '=' + dval + '&'
      })
      post_data = post_data.slice(0, -1)
    }

    var active = ""
    if (query.name == current_query) {
      active = 'class="active" '
    }
    nav_bar += '<a ' + active + ' href="' + query.name + post_data + '">' +
                 '<i class="' + query.icon + '"></i><br />' +  query.name +
               '</a>'
  })
  return nav_bar
}

var queries = sql.queries()
queries.forEach(function(query) {
  console.log("Loading route for /" + query.name)

  engine.get('/' + query.name, (request, response) => {
    var params = []
    query.params.forEach(function(param_name) {
      params.push(request.query[param_name])
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
        columns: columns,
        nav_bar: query_nav_bar(queries, query.name)
      })
    }).catch((err) => {
      console.log('Error!', err)
    })
  })
})

engine.listen()
