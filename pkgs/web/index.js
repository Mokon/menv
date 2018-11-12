const engine = require('./engine.js');
const genealogy = require('./genealogy.js');
const health = require('./health.js');
const realestate = require('./realestate.js');

var staticPages = [
  "contact",
  "newspaper",
  "guide",
  "directions",
  "portfolio",
  "genealogy/",
  "",
];

var staticDataPages = [
  "crafts",
];

genealogy.generateRoutes(engine);
realestate.generateRoutes(engine);
health.generateRoutes(engine);
engine.generateRoutes(staticPages, staticDataPages);

engine.run();
