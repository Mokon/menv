const express = require('express');
const exphbs = require('express-handlebars');
const serveindex = require('serve-index');
const fs = require('fs');

const port = 1337;

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
    defaultLayout: 'mokon_net'
});

const app = express();
app.engine('handlebars', hbs.engine);
app.set('view engine', 'hbs');

module.exports.get = function() {
    console.log(`Creating page route ${arguments[0]}`);
    app.get.apply(app, arguments);
}

module.exports.generateRoutes = function(staticPages, staticDataPages) {
    app.use(express.static('public'));
    app.use('/files', serveindex('files'));
    app.use('/files', express.static('files'));

    function renderSimplePage(path, page) {
        module.exports.get(path, (request, response) => { response.render(page, {}) });
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
};

module.exports.run = function() {
    app.listen(port, (err) => {
        if (err) {
            return console.log('Error!', err);
        }

        console.log(`The server is listening on ${port}.`);
    });
};
