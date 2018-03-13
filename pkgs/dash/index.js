const db = require('./db.js');
const engine = require('./engine.js');

engine.get('/', (request, response) => {
  response.render('dash', {
    task_groups: db.dash(),
  })
})

engine.get('/dash', (request, response) => {
  response.render('dash', {
    task_groups: db.dash()
  })
})

engine.get('/failures', (request, response) => {
  db.failures().then((result) => {
    response.render('failures', {
      failures: result
    })
  }).catch((err) => {
    console.log('Error!', err)
  })
})

engine.get('/failure_by_suite', (request, response) => {
  var num_days=request.param('num_days');
  var suite_name=request.param('suite_name');

  db.failure_by_suite(num_days, suite_name).then((result) => {
    response.render('failure', {
      failure: result
    })
  }).catch((err) => {
    console.log('Error!', err)
  })
})

engine.get('/failure_by_test', (request, response) => {
  var num_days=request.param('num_days');
  var test_name=request.param('test_name');

  db.failure_by_test(num_days, test_name).then((result) => {
    response.render('failure', {
      failure: result
    })
  }).catch((err) => {
    console.log('Error!', err)
  })
})

engine.listen()
