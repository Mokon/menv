const fs = require('fs')
const client = require('mariasql')

var config = JSON.parse(fs.readFileSync('./dash.json', 'utf8'))

function add_links(row) {
  if (row.hasOwnProperty('bb')) {
    row.bb = "<a href=\"" + config["bitbucket-url"]
      + row.bb + "\">" + row.bb + "</a>"
  }

  if (row.hasOwnProperty('jira')) {
    row.jira = "<a href=\"" + config["jira-url"]
      + row.jira + "\">" + row.jira + "</a>"
  }

  if (row.hasOwnProperty('suite_name')) {
    row.suite_name = "<a href=\"failure_by_suite?num_days=7&suite_name=" + row.suite_name
      + "\">" + row.suite_name + "</a>"
  }

  if (row.hasOwnProperty('test_name')) {
    row.test_name = "<a href=\"failure_by_test?num_days=7&test_name=" + row.test_name
      + "\">" + row.test_name + "</a>"
  }

  if (row.hasOwnProperty('user')) {
    row.user = "<a href=\"failure_by_user?num_days=7&user=" + row.user
      + "\">" + row.user + "</a>"
  }

  if (row.hasOwnProperty('link')) {
    row.link = row.link + " <a href=\"" + config["jenkins-url"]
      + row.link + "\">jenkins</a>"
      + "   <a href=\"failure_by_run?num_days=7&run=" + row.link
      + "\">failure by run</a>"
  }
}

config.groups.forEach(function(group) {
  group.tasks.forEach(add_links);
})

module.exports.query = function(query) {
  return new Promise(function(resolve, reject) {
    var db = new client({
      host: config["host"],
        user: config["user"],
        password: config["password"],
        db: config["db"]
    })

    console.log("Sending query: " + query)

    db.query(query,
      function(err, rows) {
        if (err) {
          reject(err)
        } else {
          rows.forEach(add_links)
          var i = 0
          rows.forEach(function(row){
            row.idx = i++
          })
          resolve(rows)
        }

        db.end()
      })
  })
}

module.exports.dash = function() {
  return config.groups
}
