const fs = require('fs')
const client = require('mariasql')

String.prototype.format = function () {
  var args = [].slice.call(arguments)
  return this.replace(/(\{\d+\})/g, function (a){
    return args[+(a.substr(1,a.length-2))||0]
  })
}

var config = JSON.parse(fs.readFileSync('./dash.json', 'utf8'))

function add_links(row) {
  if (row.bb != "") {
    row.bb = "<a href=\"" + config["bitbucket-url"]
      + row.bb + "\">" + row.bb + "</a>"
  }

  if (row.jira != "") {
    row.jira = "<a href=\"" + config["jira-url"]
      + row.jira + "\">" + row.jira + "</a>"
  }

  if (row.suite_name != "") {
    row.suite_name = "<a href=\"failure_by_suite?num_days=7&suite_name=" + row.suite_name
      + "\">" + row.suite_name + "</a>"
  }

  if (row.test_name != "") {
    row.test_name = "<a href=\"failure_by_test?num_days=7&test_name=" + row.test_name
      + "\">" + row.test_name + "</a>"
  }

  if (row.link != "") {
    row.link = "<a href=\"" + config["jenkins-url"]
      + row.link + "\">" + row.link + "</a>"
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

    db.query(query,
      function(err, rows) {
        if (err) {
          reject(err)
        } else {
          rows.forEach(add_links)
          resolve(rows)
        }

        db.end()
      })
  })
}

module.exports.dash = function() {
  return config.groups
}

module.exports.failures = function() {
  return module.exports.query(config["failures-query"])
}

module.exports.failure_by_suite = function(num_days, suite_name) {
  return module.exports.query(
    config["suite-failure-query"].format(num_days, suite_name))
}

module.exports.failure_by_test = function(num_days, test_name) {
  return module.exports.query(
    config["test-failure-query"].format(num_days, test_name))
}
