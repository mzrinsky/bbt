
const path = require('path');
const fs = require('node:fs');
const fsp = require('node:fs').promises;
const toml = require('toml');
const YAML = require('yaml');

async function loadConfigFile(filename) {
  let configData = {};
  const configFileData = await fsp.readFile(filename, "utf8")
  const fileExt = path.extname(filename)
  if (fileExt == ".json") {
    configData = JSON.parse(configFileData)
  } else if (fileExt == ".toml") {
    configData = toml.parse(configFileData)
  } else if (fileExt == ".yaml" || fileExt == ".yml") {
    configData = YAML.parse(configFileData)
  } else {
    throw new Error("bbt-cli only supports json, toml, and yaml config files.")
  }
  return configData;
}

exports.loadConfigFile = loadConfigFile;
