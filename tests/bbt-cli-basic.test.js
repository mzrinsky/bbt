const bbtCli = require('../bbt-cli')

const configLoader = require('../bbt-config-loader');

test('Validate Backup Config Schema', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-cli-basic-test-backup.json')
  const {error, value} = bbtCli.backupConfigSchema.validate(appConfig)
  expect(error).toBe(undefined)
  expect(value).toMatchObject(appConfig)
});

test('Validate Restore Config Schema', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-cli-basic-test-restore.json')
  const {error, value} = bbtCli.restoreConfigSchema.validate(appConfig)
  expect(error).toBe(undefined)
  expect(value).toMatchObject(appConfig)
});

test('Validate Bash Backup Template Options', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-cli-basic-test-backup.json')
  const templateOptions = bbtCli.getTemplateOptions(appConfig, {}, '.bash-backup-template')
  const {error, value} = bbtCli.backupTemplateSchema.validate(templateOptions)
  expect(error).toBe(undefined)
  expect(value).toMatchObject(templateOptions)
})

test('Validate Bash Restore Template Options', async () => {
  const appConfig = await configLoader.loadConfigFile('tests/data/bbt-cli-basic-test-restore.json')
  const templateOptions = bbtCli.getTemplateOptions(appConfig, {}, '.bash-restore-template')
  const {error, value} = bbtCli.restoreTemplateSchema.validate(templateOptions)
  expect(error).toBe(undefined)
  expect(value).toMatchObject(templateOptions)
})

