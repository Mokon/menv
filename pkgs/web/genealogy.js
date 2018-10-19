const fs = require('fs');
const showdown  = require('showdown');
  			
converter = new showdown.Converter();

function uppercase_first(string)
{
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function pretty_print(surname, id) {
    sid = id.split('_');
    ret = ""
    birth = sid[sid.length-2];
    death = sid[sid.length-1];
    sid.length = sid.length - 2;

    sid.forEach(function (item, index) 
    { 
      ret += uppercase_first(item) + " ";
    });
    return ret + uppercase_first(surname) + " (" + birth + "-" + death + ")";
}

module.exports.person = function(dir, surname, id) {
    file = dir + "/people/" + surname + "/" + id + "/description.txt";
    return "<h1>" + pretty_print(surname, id) + "</h1>" + 
      converter.makeHtml(fs.readFileSync(file, "utf8"));
}

module.exports.people = function(dir) {
    peopledir = dir + "/people";

    page="<ul>"
	  files = fs.readdirSync(peopledir);
		files.forEach(function(surname) {
        if (fs.statSync(peopledir + '/' + surname).isDirectory()) {
	        pfiles = fs.readdirSync(peopledir + '/' + surname);
		      pfiles.forEach(function(id) {
              page += "<li><a href='/genealogy/person/" + surname  + "/"
              + id + "'>" + pretty_print(surname, id) + "</a></li>";
          });
        }
		});
    page+="</ul>"
    return page;
}
