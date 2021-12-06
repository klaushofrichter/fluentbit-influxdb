//
// simple random number server with metrics and logs
//

const package = require("./package.json");
const express = require("express");
const os = require("os");
const chance = require("chance").Chance();
const winston = require("winston");

// setup express worker
const worker = express();
const workerPort = 3000;

// create a JSON info object with some application information 
const info = {
  launchDate: new Date().toLocaleString("en-US", { timeZone: "America/Chicago" }),
  serverName: chance.first() + " the " + chance.animal(),
  appName: package.name,
  serverVersion: package.version
};

// setup logging
const logger = winston.createLogger({
  level: "debug",
  defaultMeta: {
    app: package.name,
    server: info.serverName,
    version: package.version,
  },
  transports: [
    new winston.transports.Console({ level: "debug" }), 
  ],
});

// setup metrics 
const promBundle = require("express-prom-bundle");
const metricsMiddleware = promBundle({
  includePath: true,
  includeMethod: true,
  includeUp: true,
  metricsPath: "/service/metrics",
  httpDurationMetricName: package.name + "_http_request_duration_seconds",
});
worker.use("/*", metricsMiddleware);
const prom = require("prom-client");
const infoGauge = new prom.Gauge({
  name: package.name + "_server_info",
  help: package.name + " server info provides build and runtime information",
  labelNames: [
    "launchDate",
    "serverName",
    "appName",
    "serverVersion",
  ],
});
infoGauge.set(info, 1);
prom.register.metrics();

// info handler
worker.get("/service/info", (req, res) => {
  logger.http("/service/info");
  res.status(200).send(info);
});

// random handler
worker.get("/service/random", (req, res) => { 
  logger.http("/service/random");
  var r=Math.floor((Math.random()*100));
  logger.debug("random value generated: "+r);
  res.status(200).send({ random: r });
});

// start listening 
worker.listen(workerPort, () => {
  logger.info(JSON.stringify(info));
  logger.info("\"" + info.serverName + "\" started listening on http://localhost:" + workerPort + "/service/");
});
