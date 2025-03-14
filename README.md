# bbt - Better Backup Tool

> A proven approach to backup & restore in a modern wrapper.
> bbt uses config files so you can define your backups as code.
> restores are just as easy.

[![License][license-image]][license-url]

## What is it?

A tool to create and restore backup snapshots using config files on \*nix
systems.

## What does it do?

BBT uses a configuration file to backup resources to a compressed archive.

BBT can also use a configuration file to restore resources from a compressed
archive.

BBT supports json, toml, and yaml configs.

BBT is a wrapper around cat, tar, pigz (or any archiver you wish), ssh, and
pipes.

For use on legacy systems BBT has the ability to generate standalone bash
scripts.  These scripts are portable, clean, and designed to be easily modified
on-the-fly if needed.

## Roadmap

- [x] Generate Bash Scripts
- [x] Unit Test Bash Scripts
- [ ] Add backup / restore directly to bbt.js (as a lib)
- [ ] Better Documentation
- [ ] Make a nice UI interface to editing config files (so that it is really
  easy to choose what to backup / restore etc.)
- [ ] Add UI around running backup / restores.

## Config Examples

For now take a look at the bats- configs in the [/tests](tests/) directory, they
generate the scripts used in the unit tests.

## Installing

### From Source

`git clone https://github.com/mzrinsky/bbt.git`

## Usage

```bash
# to generate a backup script
bbt bash-backup -c my-system-backup-config.yaml -o ~/bin/run-system-backup

#  to generate a restore script
bbt bash-restore -c my-system-restore-config.yaml -o ~/bin/run-system-restore
```

## Support BBT

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A74VYT1)

## License

This project is licensed under the terms of the MIT license.

[![License][license-image]][license-url]

[license-image]: https://img.shields.io/github/license/mzrinsky/bbt.svg
[license-url]: https://opensource.org/licenses/MIT
