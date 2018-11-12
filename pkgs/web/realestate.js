const { google } = require('googleapis');
const fs = require('fs');

var secret = fs.readFileSync('secrets/api_key', 'utf8').replace(/(\r\n\t|\n|\r\t)/gm,"");
var realestateMapStyle = fs.readFileSync('realestateMapStyle.json');

const gClient = require('@google/maps').createClient({
    key: secret
});

var placesOfInterest = [
    "Target, 11 Andrews Rd, Somersworth, NH 03878",
    "Target, 1450 Greenland Rd #1, Greenland, NH 03840",
    "Hannaford Supermarket, 800 Islington St, Portsmouth, NH 03801",
    "Walmart, 2200 Woodbury Ave, Newington, NH 03801",
    "Hannaford Supermarket, 833 Central Ave, Dover, NH 03820",
    "Shaw's, 1600 Woodbury Ave #28, Portsmouth, NH 03801",
    "Trader Joe's, 45 Gosling Rd, Portsmouth, NH 03801",
    "Berwick Academy, 31 Academy St, South Berwick, ME 03908",
    "Hannaford Supermarket, 30 Grapevine Dr, Dover, NH 03820",
    "The Home Depot, 100 Arthur F Brady Dr, Portsmouth, NH 03801",
    "The Home Depot, 35 Lafayette Rd, North Hampton, NH 03862",
    "Hannaford Supermarket, 141 Portsmouth Ave, Exeter, NH 03833",
    "Hannaford Supermarket, 7 Mill Rd, Durham, NH 03824",
    "Hannaford Supermarket, 5 Hannaford Dr, York, ME 03909",
    "Shaw's, 851 Central Ave, Dover, NH 03820",
    "Walmart Supercenter, 59 Waltons Way, Somersworth, NH 03878",
    "Walmart Supercenter, 116 Farmington Rd, Rochester, NH 03867",
    "Shaw's, 100 Shaw's Ln, Stratham, NH 03885",
    "Hannaford Supermarket, 630 Lafayette Rd, Hampton, NH 03842",
    "Shaw's, 33 Lafayette Rd #4, North Hampton, NH 03862",
    "The Home Depot, 35 Lafayette Rd, North Hampton, NH 03862",
    "Walmart Supercenter, 700 Lafayette Rd #1, Seabrook, NH 03874",
    "Walmart Supercenter, 2460 Lafayette Rd, Portsmouth, NH 03801",
    "Hobby Lobby, 570 Lafayette Rd, Seabrook, NH 03874",
    "Hobby Lobby, 120 Marketplace Boulevard #3, Rochester, NH 03867",
    "Facebook, 100 Binney St, Cambridge, MA 02142",
    //"Target, 80 D'Amante Dr, Concord, NH 03301",
    //"Walmart Supercenter, 344 Loudon Rd, Concord, NH 03301",
    //"Shaw's, 20 D'Amante Dr, Concord, NH 03301",
    //"Hannaford Supermarket, 174 1st New Hampshire Turnpike, Northwood, NH 03261",
    //"The Home Depot, 42 D'Amante Dr, Concord, NH 03301",
];

var dests = [
    { name: "Target", icon: "target.png" },
    { name: "Hannaford", icon: "hannaford.jpg" },
    { name: "Walmart", icon: "walmart.png" },
    { name: "Shaw's", icon: "shaws.jpg" },
    { name: "Berwick Academy", icon: "berwickacademy.jpg" },
    { name: "Home Depot", icon: "homedepot.jpg" },
    { name: "Hobby Lobby", icon: "hobbylobby.jpg" },
    { name: "Facebook", icon: "facebook.png" },
];

function geocode(house, callback) {
    gClient.geocode({'address': house},
        function(err, response) {
            if ( !err) {
                console.log(response.json.results);
                // TODO
            }
        });
}


function getNearestPlacesOfInterest(house, callback) {
    gClient.distanceMatrix({
        origins: placesOfInterest,
        destinations: [house],
        mode: 'driving',
        units: 'imperial'
    }, function (err, response) {
        if (!err) {
            placesOfInterest = placesOfInterest.map(function(name) {
                return {
                    'name': name,
                    address: 'tbd',
                    distance: 'tbd',
                    duration: 'tbd',
                    durationValue: 'tbd'
                };
            });

            var origins = response.json.origin_addresses;
            var destinations = response.json.destination_addresses;
            for (var i = 0; i < origins.length; i++) {
                var results = response.json.rows[i].elements;
                for (var j = 0; j < results.length; j++) {
                    placesOfInterest[i].address = origins[i];
                    placesOfInterest[i].distance = results[j].distance.text;
                    placesOfInterest[i].duration = results[j].duration.text;
                    placesOfInterest[i].durationValue = results[j].duration.value;
                }
            }
        }

        var nearestPlacesOfInterest = dests.map(function(dest) {
            if (!dest) { return null;};
            var ofType = placesOfInterest.filter(place => dest && place && place.name && place.name.includes(dest.name));
            var sorted = ofType.sort(function(a,b) {
                return a && b && a.durationValue > b.durationValue;});

            var nearest = sorted[0];
            nearest.dest = dest.name;
            nearest.icon = "/realestate/" +  dest.icon;
            return nearest;
        });
        callback(nearestPlacesOfInterest);

    });
}

module.exports.generateRoutes = function(engine) {
    var house = "272 North Rd. Epsom NH";
    getNearestPlacesOfInterest(house, function(nearestPlacesOfInterest) {
        engine.get('/realestate', (request, response) => {
            response.render('realestate', {
                'nearestPlacesOfInterest': nearestPlacesOfInterest,
                'house': house,
                'key': secret
            });
        });

        engine.get('/realestate.js', (request, response) => {
            response.render('realestate_js', {
                layout: false,
                'nearestPlacesOfInterest': nearestPlacesOfInterest,
                'house': house,
                'key': secret,
                'realestateMapStyle': realestateMapStyle
            });
        });
    });
}
