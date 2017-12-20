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

var data = require("./dash.json");
for(var row in data["tasks"]) {
  if (data["tasks"][row].bb != "") {
    data["tasks"][row].bb = "<a href=\"" + data["bitbucket-url"]
      + data["tasks"][row].bb + "\">" + data["tasks"][row].bb + "</a>"
  }

  if (data["tasks"][row].jira != "") {
    data["tasks"][row].jira = "<a href=\"" + data["jira-url"]
      + data["tasks"][row].jira + "\">" + data["tasks"][row].jira + "</a>"
  }
}

app.engine('handlebars', hbs.engine);
app.set('view engine', 'handlebars');

app.get('/', (request, response) => {
  response.render('home', {
    data: data["tasks"]
  })
})

app.listen(port, (err) => {
  if (err) {
    return console.log('Error!', err)
  }

  console.log(`The server is listening on ${port}.`)
})
