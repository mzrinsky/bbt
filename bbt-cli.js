#!/usr/bin/env node

const { program } = require('commander');
const fs = require('node:fs');
const fsp = require('node:fs').promises;
const easyConfig = require('./bbt-config-loader.js');
const Joi = require('joi');

program
.option('-c, --config <string>', 'Specify the config file to load', './config.json')

program
.command('backup')

program
.command('restore')

program
.command('bash-backup')
.description("Generate a bash backup script from a bbt config file.")
.option('-o, --output <string>', 'Write output to file instead of STDOUT')
.action(async (options) => {
  generateScript(options, '.bash-backup-template')
})

program
.command('bash-restore')
.description("Generate a bash restore script from a bbt config file.")
.option('-o, --output <string>', 'Write output to file instead of STDOUT')
.action(async (options) => {
  generateScript(options, '.bash-restore-template')
})

const backupConfigSchema = Joi.object({
  backupDest: Joi.string().required(),
  destSshOpts: Joi.array(),
  archiveBaseName: Joi.string().required(),
  archiveCommand: Joi.string(),
  archiveExtension: Joi.string(),
  archiveLinkLatest: Joi.bool(),
  archiveOwner: Joi.string().allow(''),
  archivePermissions: Joi.string().allow(''),
  archiveKeepLast: Joi.number(),
  backupSrc: Joi.string().required(),
  srcSshOpts: Joi.array(),
  resources: Joi.array().required(),
  excludes: Joi.array(),
})
exports.backupConfigSchema = backupConfigSchema

const restoreConfigSchema = Joi.object({
  restoreSrc: Joi.string().required(),
  srcSshOpts: Joi.array(),
  restoreDest: Joi.string().required(),
  destSshOpts: Joi.array(),
  restoreResources: Joi.array().required(),
  excludes: Joi.array(),
})
exports.restoreConfigSchema = restoreConfigSchema

const backupTemplateSchema = Joi.object({
  backup_src: Joi.string().required(),
  backup_dest: Joi.string().required(),
  backup_src_ssh_opts: Joi.string().required(),
  backup_dest_ssh_opts: Joi.string().required(),
  archive_command: Joi.string(),
  archive_base_name: Joi.string().required(),
  archive_extension: Joi.string().required(),
  archive_link_latest: Joi.bool().required(),
  archive_owner: Joi.string().required(),
  archive_perms: Joi.string().required(),
  archive_keep_last: Joi.number().required(),
  backup_resources: Joi.string().required(),
  backup_exclude_resources: Joi.string().required(),
})
exports.backupTemplateSchema = backupTemplateSchema

const restoreTemplateSchema = Joi.object({
  restore_src: Joi.string().required(),
  restore_dest: Joi.string().required(),
  restore_src_ssh_opts: Joi.string().required(),
  restore_dest_ssh_opts: Joi.string().required(),
  restore_resources: Joi.string().required(),
  restore_exclude_resources: Joi.string().required(),
})
exports.restoreTemplateSchema = restoreTemplateSchema

async function generateScript(options, templateName) {
  let programOpts = program.opts()

  const appConfig = await loadConfig(programOpts.config)

  let templateOptions = getTemplateOptions( appConfig, options, templateName )
  const processedTemplate = await processTemplate(templateName, templateOptions)

  if ( options.output ) {
    writeBashScript(options.output , processedTemplate)
  } else {
    console.log(processedTemplate)
  }

}
exports.generateScript = generateScript

function isDataValid(validationSchema, inputData) {
  const { error, value } = validationSchema.validate(inputData)
  if (error) {
    return false
  }
  return true
}
exports.isDataValid = isDataValid

// TODO: Validate the appConfig, and cmdOptions..
// TODO: Validate te output before processing tempates.. (so we know it contains expected data.)
function getTemplateOptions(appConfig, cmdOptions, templateName) {
  let templateOptions = {};

  if (templateName == '.bash-restore-template') {

    const {error, value} = restoreConfigSchema.validate(appConfig)
    if (error) {
      const configFile = program.opts().config
      console.error(`The config file '${configFile}' failed validation.`, error)
      process.exit(1)
    }

    let restoreSrc = appConfig.restoreSrc
    let restoreSrcUrl;
    if (restoreSrc.startsWith("ssh://")) {
      restoreSrcUrl = new URL(restoreSrc)
    }

    let restoreDest = appConfig.restoreDest
    let restoreDestUrl;
    if (restoreDest.startsWith("ssh://")) {
      restoreDestUrl = new URL(restoreDest)
    }

    let restoreSrcSshOpts = ""
    if (appConfig.srcSshOpts != undefined) {
      restoreSrcSshOpts = appConfig.srcSshOpts.join(" ")
      if (restoreSrcSshOpts != "") {
        restoreSrcSshOpts = restoreSrcSshOpts + " "
      }
    }

    let restoreDestSshOpts = ""
    if (appConfig.destSshOpts != undefined) {
      restoreDestSshOpts = appConfig.destSshOpts.join(" ")
      if (restoreDestSshOpts != "") {
        restoreDestSshOpts = restoreDestSshOpts + " "
      }
    }


    /*
    // this should get refactored.. currently it will just barf if the restore list or the excludes
    // (or really the entire command line) is too long.. if we are that long we can use tmp files and the file-from options.
    if (new Blob([restoreResourceStr]).size >= 2097000 ) {
      console.warn("You might start having problems with the restore resources command line being too long.. sorry.");
    }
    */

    let restoreResourceStr = ""
    if ( appConfig.restoreResources != undefined ) {
      restoreResourceStr = "\t\"" + appConfig.restoreResources.join("\"\n\t\"") + "\"";
    }

    let excludeStr = ""
    if ( appConfig.excludes != undefined ) {
      excludeStr = "\t\"" + appConfig.excludes.join("\"\n\t\"") + "\""
    }

    let restoreOptsStr = ""
    if ( appConfig.remoteRestoreOpts != undefined ) {
      restoreOptsStr = appConfig.remoteRestoreOpts.join(" ")
      if (restoreOptsStr != "") {
        restoreOptsStr = restoreOptsStr + " "
      }
    }

    templateOptions = {
      "restore_src": appConfig.restoreSrc || "",
      "restore_dest": appConfig.restoreDest,
      "restore_src_ssh_opts": restoreSrcSshOpts,
      "restore_dest_ssh_opts": restoreDestSshOpts,
      "restore_resources": restoreResourceStr,
      "restore_exclude_resources": excludeStr,
    }

    const {terror, tvalue} = restoreTemplateSchema.validate(templateOptions)
    if (terror) {
      const configFile = program.opts().config
      console.error(`The template options from '${configFile}' failed validation, this is probably a bug.`, terror)
      process.exit(1)
    }

  } else {

    const {error, value} = backupConfigSchema.validate(appConfig)
    if (error) {
      const configFile = program.opts().config
      console.error(`The config file '${configFile}' failed validation.`, error)
      process.exit(1)
    }

    let backupSrc = appConfig.backupSrc
    let backupSrcUrl;
    if (backupSrc.startsWith("ssh://")) {
      backupSrcUrl = new URL(backupSrc)
    }

    let backupDest = appConfig.backupDest
    let backupDestUrl;
    if (backupDest.startsWith("ssh://")) {
      backupDestUrl = new URL(backupDest)
    }

    let resourceStr = ""
    if ( appConfig.resources != undefined && appConfig.resources.length > 0 ) {
      resourceStr = "\t\"" + appConfig.resources.join("\"\n\t\"") + "\""
    }

    let excludeStr = ""
    if ( appConfig.excludes != undefined && appConfig.excludes.length > 0 ) {
      excludeStr = "\t\"" + appConfig.excludes.join("\"\n\t\"") + "\""
    }

    let archiveBaseNameStr = appConfig.archiveBaseName || "bbt-backup-snapshot"

    let backupSrcSshOpts = ""
    if (appConfig.srcSshOpts != undefined) {
      backupSrcSshOpts = appConfig.srcSshOpts.join(" ")
      if (backupSrcSshOpts != "") {
        backupSrcSshOpts = backupSrcSshOpts + " "
      }
    }

    let backupDestSshOpts = ""
    if (appConfig.destSshOpts != undefined) {
      backupDestSshOpts = appConfig.destSshOpts.join(" ")
      if (backupDestSshOpts != "") {
        backupDestSshOpts = backupDestSshOpts + " "
      }
    }

    templateOptions = {
      "backup_src": backupSrc,
      "backup_dest": backupDest,
      "backup_src_ssh_opts": backupSrcSshOpts,
      "backup_dest_ssh_opts": backupDestSshOpts,
      "backup_resources": resourceStr,
      "backup_exclude_resources": excludeStr,
      "archive_base_name": archiveBaseNameStr,
      "archive_link_latest": appConfig.archiveLinkLatest ?? true,
      "archive_owner": appConfig.archiveOwner,
      "archive_perms": appConfig.archivePermissions || "",
      "archive_command": appConfig.archiveCommand || "pigz --fast",
      "archive_extension": appConfig.archiveExtension || ".tar.gz",
      "archive_keep_last": appConfig.archiveKeepLast || 0,
    }

    const {terror, tvalue} = backupTemplateSchema.validate(templateOptions)
    if (terror) {
      const configFile = program.opts().config
      console.error(`The template options from '${configFile}' failed validation, this is probably a bug.`, terror)
      process.exit(1)
    }
  }
  return templateOptions;
}
exports.getTemplateOptions = getTemplateOptions

async function processTemplate(fileName, templateData) {
  let fileData = await fsp.readFile(fileName, "utf8")
  // iterate all the keys in the templateData..
  // use them as the values to replace..
  for (const [key, val] of Object.entries(templateData)) {
    const findStr = `{{!${key}}}`
    fileData = fileData.replaceAll( findStr, val )
  }
  return fileData
}

async function loadConfig(fileName) {
  try {
    return await easyConfig.loadConfigFile(fileName)
  } catch (err) {
    console.error("Failed loading config: ", err)
    process.exit(1)
  }
}

function writeBashScript(outputFile, fileData) {
  fs.writeFileSync(outputFile, fileData);
  fs.chmod(outputFile, 0o755, (err) => {
    if (err) {
      console.error("Failed to chmod generated file ", err)
    }
  });
}

if (process.env.NODE_ENV !== 'test') {
  program.parse()
} else {
  console.debug("test environment detected, skipping normal program execution.")
}
