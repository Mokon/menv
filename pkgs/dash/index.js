const express = require('express')
const exphbs = require('express-handlebars')
const fs = require('fs');

const port = 1337

var hbs = exphbs.create({
    helpers: {
        json: function (context) { return JSON.stringify(context); }
    },
    defaultLayout: 'main'
});

const app = express()

var data = JSON.parse(fs.readFileSync('./dash.json', 'utf8'));

app.engine('handlebars', hbs.engine);
app.set('view engine', 'handlebars');

app.get('/', (request, response) => {
  response.render('home', {
    data: data
  })
})

app.listen(port, (err) => {
  if (err) {
    return console.log('Error!', err)
  }

  console.log(`The server is listening on ${port}.`)
})
