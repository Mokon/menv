// Might be cool to use: https://nanogallery2.nanostudio.org/
const engine = require('./engine.js');
const genealogy = require('./genealogy.js');
const google = require('./google.js');

engine.get('/', (request, response) => {
  response.render('index', {})
})

engine.get('/home', (request, response) => {
  response.render('index', {})
})

gpath="/home/dbond/genealogy"

engine.get('/genealogy/people', (request, response) => {
  response.render('genealogy',
    {page: genealogy.people(gpath)})
})

engine.get('/genealogy/person/:surname/:id', (request, response) => {
  response.render('genealogy',
    {page: genealogy.person(gpath,
                            request.params.surname,
                            request.params.id)})
})

engine.get('/contact', (request, response) => {
  response.render('contact', {})
})

engine.get('/newspaper', (request, response) => {
  response.render('newspaper', {})
})

engine.get('/guide', (request, response) => {
  response.render('guide', {})
})

engine.get('/directions', (request, response) => {
  response.render('directions', {})
})

engine.get('/crafts', (request, response) => {
  response.render('crafts', {})
})

engine.get('/portfolio', (request, response) => {
  response.render('portfolio', {})
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

engine.get('/kids-health-stats', (request, response) => {
  google.spreadsheet(render.bind(null, response),
    '17zFROiQrXDe5HdZr8f0Bvy7vclVqnxdCuW4laiGSi_4')
})


engine.listen()
