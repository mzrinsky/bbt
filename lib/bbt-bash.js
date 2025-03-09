
/*!
  BBT - Better Backup Tool Bash Generator
  @author Matt Zrinsky [matt.zrinsky@gmail.com]
  @license MIT
*/

const fs = require('node:fs');
const fsp = require('node:fs').promises;
const path = require('path');

const Validator = require('jsonschema').Validator;
const validator = new Validator()

const backupTemplateSchema = {
  type: 'object',
  id: '/BackupTemplateSchema',
  required: true,
  properties: {
    backup_src: { type: 'string', required: true },
    backup_dest: { type: 'string', required: true },
    backup_src_ssh_opts: { type: 'string', required: true },
    backup_dest_ssh_opts: { type: 'string', required: true },
    archive_command: { type: 'string', required: true },
    archive_base_name: { type: 'string', required: true },
    archive_extension: { type: 'string', required: true },
    archive_link_latest: { type: 'boolean', required: true },
    archive_owner: { type: 'string', required: true },
    archive_perms: { type: 'string', required: true },
    archive_keep_last: { type: 'number', required: true},
    backup_resources: { type: 'string', required: true },
    backup_exclude_resources: { type: 'string', required: true }
  }
}
exports.backupTemplateSchema = backupTemplateSchema

const restoreTemplateSchema = {
  type: 'object',
  id: '/RestoreTemplateSchema',
  required: true,
  properties: {
    restore_src: { type: 'string', required: true },
    restore_dest: { type: 'string', required: true },
    restore_src_ssh_opts: { type: 'string', required: true },
    restore_dest_ssh_opts: { type: 'string', required: true },
    restore_resources: { type: 'string', required: true },
    restore_exclude_resources: { type: 'string', required: true },
    extract_command: { type: 'string', required: true },
  }
}
exports.restoreTemplateSchema = restoreTemplateSchema

async function runCommand(commandName, config, options) {

  let templateOptions = getTemplateOptions( commandName, config, options )

  const templateName =  path.join(__dirname, `.${commandName}-template`)
  const processedTemplate = await processTemplate(templateName, templateOptions)

  if ( options.output ) {
    writeBashScript(options.output , processedTemplate)
  } else {
    console.log(processedTemplate)
  }
}
exports.runCommand = runCommand


function getTemplateOptions(scriptType, appConfig, cmdOptions) {
  let templateOptions = {};

  if (scriptType == 'bash-restore') {

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
      "extract_command": appConfig.extractCommand || "gunzip",
      "restore_resources": restoreResourceStr,
      "restore_exclude_resources": excludeStr,
    }

    const result = validator.validate(templateOptions, restoreTemplateSchema)
    if ( result.errors.length > 0 ) {
      console.error(`The template options from '${cmdOptions.config}' failed validation, this is probably a bug.`, result.errors[0].stack)
      process.exit(1)
    }

  } else if (scriptType == "bash-backup") {

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
      "archive_owner": appConfig.archiveOwner || "",
      "archive_perms": appConfig.archivePermissions || "",
      "archive_command": appConfig.archiveCommand || "pigz --fast",
      "archive_extension": appConfig.archiveExtension || ".tar.gz",
      "archive_keep_last": appConfig.archiveKeepLast || 0,
    }

    //const {terror, tvalue} = backupTemplateSchema.validate(templateOptions)
    const result = validator.validate(templateOptions, backupTemplateSchema)
    if ( result.errors.length > 0 ) {
      console.error(`The template options from '${cmdOptions.config}' failed validation, this is probably a bug.`, result.errors[0].stack)
      process.exit(1)
    }
  }
  return templateOptions;
}
exports.getTemplateOptions = getTemplateOptions

async function processTemplate(fileName, templateData) {
  let fileData = await fsp.readFile(fileName, "utf8")
  // iterate all the keys in the templateData..
  // use them as the strings to replace..
  for (const [key, val] of Object.entries(templateData)) {
    const findStr = `{{!${key}}}`
    fileData = fileData.replaceAll( findStr, val )
  }
  return fileData
}

function writeBashScript(outputFile, fileData) {
  fs.writeFileSync(outputFile, fileData);
  fs.chmod(outputFile, 0o755, (err) => {
    if (err) {
      console.error("Failed to chmod generated file ", err)
    }
  });
}
