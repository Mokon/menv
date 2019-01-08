const google = require('./google.js');

module.exports.generateRoutes = function(engine) {
    engine.get('/board_game_collection', (request, response) => {
        google.processRangeFromSpreadsheet(
            '1uhbr4qn57zob9_g7DTPfnnz-KcbWEPtzzTBO27iRtBI', 'board_game_collection',
            function (rows) {
                if (rows.length) {
                    var columns = rows.shift()
                    var oColumns = []

                    columns.forEach(function(column) {
                        var oColumn = {
                            index: column,
                            title: column,
                            type: 'string',
                            flex: 1
                        };

                       oColumns.push(oColumn)
                    })
                    var data = []

                    rows.forEach(function(row) {
                        var oRow = {}
                        i = 0
                        columns.forEach(function(column) {
                            oRow[column] = row[i++]
                        })
                        data.push(oRow)
                    })

                    engine.render(request, response, 'board_game_collection', {
                        data: data,
                        columns: oColumns
                    })
                }
            });
    });
}
