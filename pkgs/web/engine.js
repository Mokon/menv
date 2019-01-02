const express = require('express');
const exphbs = require('express-handlebars');
var session = require('express-session');
const serveindex = require('serve-index');
const fs = require('fs');
var https = require('https');

const port = 8443;
var privateKey  = fs.readFileSync('secrets/server.key');
var certificate = fs.readFileSync('secrets/server.cert');
var credentials = {key: privateKey, cert: certificate};
var cookie_secret = fs.readFileSync('secrets/cookie.secret').toString();

var hbs = exphbs.create({
    helpers: {
        json: function (context) { return JSON.stringify(context); },
        if_even: function(conditional, options) {
            if((conditional % 2) == 0) {
                return options.fn(this);
            } else {
                return options.inverse(this);
            }
        }
    },
    defaultLayout: 'mokon_net',
    extname: '.hbs'
});

const app = express();
app.engine('hbs', hbs.engine);
app.set('view engine', 'hbs');
app.use(session({
  secret: cookie_secret,
  resave: true,
  saveUninitialized: true,
  cookie: { secure: false }
}))

module.exports.get = function() {
  console.log(`Creating page route ${arguments[0]}`);
  app.get.apply(app, arguments);
}

module.exports.render = function(request, response, page, params) {
  if(request.session.access_token) {
    params.access_token = request.session.access_token;
  } else {
    params.access_token = 0;
  }
  response.render(page, params);
}

module.exports.generateRoutes = function(staticPages, staticDataPages) {
    app.use(express.static('public'));
    app.use('/files', serveindex('files'));
    app.use('/files', express.static('files'));

    function renderSimplePage(path, page) {
        module.exports.get(path, (request, response) => {
            module.exports.render(request, response, page, {});
        });
    }

    staticPages.forEach(function(page) {
        if (page.endsWith('/') || page == "") {
            renderSimplePage('/' + page + "home", page + "home");
            renderSimplePage('/' + page, page + "home");
        } else {
            renderSimplePage('/' + page, page);
        }
    });

    staticDataPages.forEach(function(page) {
        module.exports.get('/' + page, (request, response) => {
            response.render(page, {
                data: JSON.parse(fs.readFileSync(page + '.json', 'utf8'))}) });
    });

    module.exports.get('/login/:access_token', (request, response) => {
        request.session.access_token = request.params.access_token
        response.render('login', {})
    })
};

var httpsServer = https.createServer(credentials, app);

module.exports.run = function() {
    httpsServer.listen(port, (err) => {
        if (err) {
            return console.log('Error!', err);
        }

        console.log(`The server is listening on ${port}.`);
    });
};
