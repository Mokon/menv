const google = require('./google.js');

module.exports.generateRoutes = function(engine) {
    engine.get('/health', (request, response) => {
        google.processRangeFromSpreadsheet(
            '17zFROiQrXDe5HdZr8f0Bvy7vclVqnxdCuW4laiGSi_4', 'kids_health_stats', 
            function (rows) {
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
                    response.render('graphs', {data: data})
                }
            });
    });
}
