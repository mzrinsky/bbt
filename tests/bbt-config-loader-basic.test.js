const configLoader = require('../lib/bbt-config-loader');

test('Missing config throws ENOENT exception', async () => {
  expect(configLoader.loadConfigFile('missing-file.json'))
    .rejects.toThrow('no such file or directory');
});

test('Unknown file type throws exception', async () => {
  expect(configLoader.loadConfigFile('tests/data/test-config.conf'))
    .rejects.toThrow('bbt-cli only supports json, toml, and yaml config files.');
})

test('Loads a test JSON config file', async () => {
  expect(configLoader.loadConfigFile('tests/data/test-config.json'))
    .resolves.toMatchObject({"test":1});
});

test('Loads a test YAML config file', async () => {
  expect(configLoader.loadConfigFile('tests/data/test-config.yaml'))
    .resolves.toMatchObject({"test":1});
});

test('Loads a test TOML config file', async () => {
  expect(configLoader.loadConfigFile('tests/data/test-config.toml'))
    .resolves.toMatchObject({"test":1});
});
