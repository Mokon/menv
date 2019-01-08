const express = require('express');
const exphbs = require('express-handlebars');
const session = require('express-session');
const serveindex = require('serve-index');
const fs = require('fs');
const https = require('https');
const request = require('request');
const FB = require('fb').default;

const port = 8443;
var privateKey  = fs.readFileSync('secrets/server.key');
var certificate = fs.readFileSync('secrets/server.cert');
var credentials = {key: privateKey, cert: certificate};
var cookie_secret = fs.readFileSync('secrets/cookie.secret').toString();
var facebook_api_secret = fs.readFileSync('secrets/facebook_api.secret').toString();
console.log(facebook_api_secret);
var facebook_app_id = '218827175668802';

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

FB.options({
  appId      : facebook_app_id,
  cookie     : true,
  xfbml      : true,
  status     : true,
  version    : 'v3.2',
  appSecret  : facebook_api_secret
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
  // We send the access_token back so the website knows if the user is signed in
  // or if it should signin again.
  if(request.session.access_token) {
    params.access_token = request.session.access_token;
  } else {
    params.access_token = 0;
  }
  response.render(page, params);
}

function priv_check(user_id) {
    return user_id == 10161417247890158;
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
            modules.exports.render(request, response, page, {
                data: JSON.parse(fs.readFileSync('data/' + page + '.json', 'utf8'))}) });
    });

    module.exports.get('/login/:access_token', (request, user_response) => {
        // TODO this is a long chain of callbacks which will have a large latency.
        FB.api('oauth/access_token', {
            client_id: facebook_app_id,
            client_secret: facebook_api_secret,
            grant_type: 'client_credentials'
        }, function (response) {
            if(!response || response.error) {
                console.log(!response ? 'error occurred' : response.error);
                return;
            }

            var app_facebook_access_token = response.access_token;
            FB.api('/debug_token', {
                input_token: request.params.access_token,
                access_token: app_facebook_access_token
            }, function(response) {
                if(!response || response.error) {
                    console.log(!response ? 'error occurred' : response.error);
                    return;
                }
                console.log(response);
                if (response.data.app_id == facebook_app_id &&
                    response.data.is_valid)
                {
                    if (priv_check(response.data.user_id))
                    {
                        request.session.priv = true;
                    }
                    request.session.access_token = request.params.access_token
                }
            });
        })
    };
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
