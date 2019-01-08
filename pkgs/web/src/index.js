const engine = require('./engine.js');
const board_game_collection = require('./board_game_collection.js');
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
  "gallery",
];

genealogy.generateRoutes(engine);
realestate.generateRoutes(engine);
health.generateRoutes(engine);
board_game_collection.generateRoutes(engine);
engine.generateRoutes(staticPages, staticDataPages);

engine.run();
