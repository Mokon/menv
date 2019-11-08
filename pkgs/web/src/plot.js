const { google } = require('googleapis');
const fs = require('fs');

var secret = fs.readFileSync('/run/secrets/api_key', 'utf8').replace(/(\r\n\t|\n|\r\t)/gm,"");

const gClient = require('@google/maps').createClient({
    key: secret
});

module.exports.generateRoutes = function(engine) {
    var house = "272 North Rd. Epsom NH";
    engine.get('/plot', (request, response) => {
        response.render('plot', {
            'key': secret,
            'house': house,
        });
    });
}
