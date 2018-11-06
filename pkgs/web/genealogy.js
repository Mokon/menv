const fs = require('fs');
const showdown  = require('showdown');

converter = new showdown.Converter();

gpath="/home/dbond/menv/pkgs/genealogy";

function uppercaseFirst(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function prettyPrint(surname, id) {
    sid = id.split('_');
    ret = "";
    birth = sid[sid.length-2];
    death = sid[sid.length-1];
    sid.length = sid.length - 2;

    sid.forEach(function (item, index) {
        ret += uppercaseFirst(item) + " ";
    });
    return ret + uppercaseFirst(surname) + " (" + birth + "-" + death + ")";
}

function person(surname, id) {
    file = gpath + "/people/" + surname + "/" + id + "/description.txt";
    var person = {
        id: id,
        surname: surname,
        name: prettyPrint(surname, id),
        description: converter.makeHtml(fs.readFileSync(file, "utf8"))
    };
    return person;
}

function people() {
    peopledir = gpath + "/people";

    ppl = [];
    files = fs.readdirSync(peopledir);
    files.forEach(function(surname) {
        if (fs.statSync(peopledir + '/' + surname).isDirectory()) {
            pfiles = fs.readdirSync(peopledir + '/' + surname);
            pfiles.forEach(function(id) {
                var person = {
                    id: id,
                    surname: surname,
                    name: prettyPrint(surname, id)
                };
                ppl.push(person);
            });
        }
    });
    return ppl;
}

module.exports.generateRoutes = function(engine) {
    engine.get('/genealogy/people', (request, response) => {
        response.render('genealogy/people', {people: people()});
    })

    engine.get('/genealogy/person/:surname/:id', (request, response) => {
        response.render('genealogy/person',
            {person: person(request.params.surname, request.params.id)})
    })
}
