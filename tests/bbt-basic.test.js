const bbtCli = require('../bbt')
const bbtBash = require('../lib/bbt-bash')

const configLoader = require('../lib/bbt-config-loader');

const Validator = require('jsonschema').Validator;
const validator = new Validator()

test('Validate Backup Config Schema', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-backup.json')
  const result = validator.validate(appConfig, bbtCli.backupConfigSchema)
  expect(result.errors.length).toBe(0)
});

test('Validate Restore Config Schema', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-restore.json')
  const result = validator.validate(appConfig, bbtCli.restoreConfigSchema)
  expect(result.errors.length).toBe(0)
});


test('Validate Bash Backup Template Options', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-backup.json')
  const templateOptions = bbtBash.getTemplateOptions('bash-backup', appConfig, {})
  const result = validator.validate(templateOptions, bbtBash.backupTemplateSchema)
  expect(result.errors.length).toBe(0)
})

test('Validate Bash Restore Template Options', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-restore.json')
  const templateOptions = bbtBash.getTemplateOptions('bash-restore', appConfig, {})
  const result = validator.validate(templateOptions, bbtBash.restoreTemplateSchema)
  expect(result.errors.length).toBe(0)
})


test('Ensure Invalid Bash Backup Template Options Fail', async () => {
  const testData = {
    backup_src: undefined,
    backup_dest: undefined,
    backup_src_ssh_opts: undefined,
    backup_dest_ssh_opts: undefined,
    archive_command: undefined,
    archive_base_name: undefined,
    archive_extension: undefined,
    archive_link_latest: undefined,
    archive_owner: undefined,
    archive_perms: undefined,
    archive_keep_last: undefined,
    backup_resources: undefined,
    backup_exclude_resources: undefined
  }
  const result = validator.validate(testData, bbtBash.backupTemplateSchema)
  expect(result.errors.length).toBe(13)
})

test('?Ensure Invalid Bash Restore Template Options Fail', async () => {
  const testData = {
    restore_src: undefined,
    restore_dest: undefined,
    restore_src_ssh_opts: undefined,
    restore_dest_ssh_opts: undefined,
    restore_resources: undefined,
    restore_exclude_resources: undefined,
    extract_command: undefined
  }
  const result = validator.validate(testData, bbtBash.restoreTemplateSchema)
  expect(result.errors.length).toBe(7)
})


test('Ensure Invalid Backup Config Fails (invalid key)', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-backup-invalid-key.json')
  const result = validator.validate(appConfig, bbtCli.backupConfigSchema)
  expect(result.errors.length).not.toBe(1)
})

test('Ensure Invalid Backup Config Fails (extra key)', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-backup-invalid-extra-key.json')
  const result = validator.validate(appConfig, bbtCli.backupConfigSchema)
  expect(result.errors.length).not.toBe(1)
})

test('Ensure Invalid Backup Config Throws Exception (invalid json)', async () => {
  expect(async () => {
    const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-backup-invalid-json.json')
  }).rejects.toThrow()
})


test('Ensure Invalid Restore Config Fails (invalid key)', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-restore-invalid-key.json')
  const result = validator.validate(appConfig, bbtCli.backupConfigSchema)
  expect(result.errors.length).not.toBe(1)
})

test('Ensure Invalid Restore Config Fails (extra key)', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-restore-invalid-extra-key.json')
  const result = validator.validate(appConfig, bbtCli.backupConfigSchema)
  expect(result.errors.length).not.toBe(1)
})

test('Ensure Invalid Restore Config Throws Exception (invalid json)', async () => {
  expect(async () => {
    const appConfig = await configLoader.loadConfigFile('tests/data/bbt-basic-test-restore-invalid-json.json')
  }).rejects.toThrow()
})
