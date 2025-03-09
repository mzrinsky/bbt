#!/usr/bin/env node

/*!
  BBT - Better Backup Tool
  @author Matt Zrinsky [matt.zrinsky@gmail.com]
  @license MIT
*/

const { program } = require('commander');
const bbtConfig = require('./lib/bbt-config-loader.js');
const bbtBash = require('./lib/bbt-bash.js');
const Validator = require('jsonschema').Validator;
const validator = new Validator()

/*
  Define a schema for backup / restore configs.
 */
const backupConfigSchema = {
  type: 'object',
  id: '/BackupConfigSchema',
  required: true,
  properties: {
    backupDest: { type: 'string', required: true },
    destSshOpts: { type: 'array' },
    archiveCommand: { type: 'string' },
    archiveBaseName: { type: 'string', required: true },
    archiveExtension: { type: 'string' },
    archiveLinkLatest: { type: 'boolean' },
    archiveOwner: { type: 'string' },
    archivePermissions: { type: 'string' },
    archiveKeepLast: { type: 'number' },
    backupSrc: { type: 'string', required: true },
    srcSshOpts: { type: 'array' },
    resources: { type: 'array', required: true },
    excludes: { type: 'array' }
  }
}
exports.backupConfigSchema = backupConfigSchema

const restoreConfigSchema = {
  type: 'object',
  id: '/RestoreConfigSchema',
  required: true,
  properties: {
    restoreSrc: { type: 'string', required: true },
    srcSshOpts: { type: 'array' },
    extractCommand: { type: 'string' },
    restoreDest: { type: 'string', required: true },
    destSshOpts: { type: 'array' },
    restoreResources: { type: 'array', required: true },
    excludes: { type: 'array' }
  }
}
exports.restoreConfigSchema = restoreConfigSchema

program
.command('bash-backup')
.description("Generate a bash backup script from a bbt config file.")
.option('-c, --config <string>', 'Specify the config file to load', './config.json')
.option('-o, --output <string>', 'Write output to file instead of STDOUT')
.action(async (options) => {
  let config = await loadConfig(options.config, backupConfigSchema)
  await bbtBash.runCommand('bash-backup', config, options)
})

program
.command('bash-restore')
.description("Generate a bash restore script from a bbt config file.")
.option('-c, --config <string>', 'Specify the config file to load', './config.json')
.option('-o, --output <string>', 'Write output to file instead of STDOUT')
.action(async (options) => {
  let config = await loadConfig(options.config, restoreConfigSchema)
  await bbtBash.runCommand('bash-restore', config, options)
})

async function loadConfig(fileName, validateSchema) {
  try {
    let loadedConfig = await bbtConfig.loadConfigFile(fileName)
    if ( validateSchema != undefined ) {
      const result = validator.validate(loadedConfig, validateSchema)
      if (result.errors.length) {
        throw(`Config failed validation: ${result.errors[0].stack}`)
      }
      return loadedConfig;
    }
  } catch (err) {
    console.error("Failed loading config: ", err)
    process.exit(1)
  }
}

if (process.env.NODE_ENV !== 'test') {
  program.parse()
}
