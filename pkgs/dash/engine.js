const express = require('express')
const exphbs = require('express-handlebars')

const port = 1337

var hbs = exphbs.create({
  helpers: {
    json: function (context) { return JSON.stringify(context); }
  },
  defaultLayout: 'main'
});

const app = express()

app.engine('handlebars', hbs.engine);
app.set('view engine', 'handlebars');
app.use(express.static('public'))

module.exports.listen = function() {
  app.listen(port, (err) => {
    if (err) {
      return console.log('Error!', err)
    }

    console.log(`The server is listening on ${port}.`)
  })
}

module.exports.get = function() {
  app.get.apply(app, arguments)
}
