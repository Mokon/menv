// Might be cool to use: https://nanogallery2.nanostudio.org/
const engine = require('./engine.js');
const google = require('./google.js');

engine.get('/', (request, response) => {
  response.render('index', {
  })
})

function render(response, rows) {
  if (rows.length) {
    var data = []

    var headers = rows.shift()
    headers.shift()
    headers.shift()

    rows.forEach(function(row) {
      var i = 2
      headers.forEach(function(header) {
    console.log(i);
        if (typeof(row[i]) != "undefined") {
          var r = {person: row[1],
                   statistic: header,
                   age: row[0],
                   value: row[i++]};

          data.push(r)
        }
      })
    })
    response.render('graphs', {
      data: data
    })
  }
}


engine.get('/graphs', (request, response) => {
  google.spreadsheet(render.bind(null, response))
})


engine.listen()
