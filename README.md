bbtcli - Better Backup Tool Command Line Interface

# Warning
This is currently a work in progress.

# What is it?
A tool to create and restore backup snapshots on *nix systems.

# What does it do?

BBT uses a configuration file to backup resources to a compressed archive.

BBT can also use a configuration file to restore resources from a compressed archive.

For use on legacy systems BBT has the ability to create a pure bash shell script, which performs the backup or restore.

# How does it work?

BBT was designed to be as simple as possible and to run on as many systems as possible.  As such the underlying functionality is provided by ssh, tar, gzip, and cat.

Shell scripts can be generated for use on legacy systems which run the same commands as the bbtcli tool, essentially removing any dependency on node or js.  (Sometimes you just need to backup and old system)

Configuration files are designed to be simple and to remove any common mistakes that would normally happen when using the underlying tools directly.

Backup and restore is possible from ssh => local, local => ssh, ssh => ssh, or local => local.

# Install

`git clone`

# Usage

`bbtcli blah`

# Configuration Examples

```
# backup-example.json
{
  "backupDest": "/tests/output/backups/",
  "destSshOpts": [],
  "archiveBaseName": "archive-basename",
  "archiveCommand": "pigz --fast",
  "archiveLinkLatest": true,
  "archiveOwner": "",
  "archivePermissions": "644",
  "archiveKeepDays": 30,
  "backupSrc": "/tests/data/input/",
  "srcSshOpts": [],
  "resources": [
    "test-dir-1",
    "test-dir-2",
    "test-dir-3",
    "test-file-1",
    "test-file-2",
    "test-file-3",
    "test-file-5"
  ],
  "excludes": ["test-dir-2/td2-test-file-1", "test-dir-2/td2-test-file-3"]
}
```

```
# restore-example.json
{
  "restoreSrc": "/tests/output/backups/latest",
  "srcSshOpts": [],
  "restoreDest": "/tests/output/restore/",
  "destSshOpts": [],
  "restoreResources": [
    "test-dir-1",
    "test-dir-2",
    "test-file-1",
    "test-file-2",
    "test-file-3"
  ],
  "excludes": ["*/td2-test-file-2"]
}
```

```
# backup-local-to-ssh-example.json
{
  "backupDest": "ssh://user@backup-host/tests/output/backups/",
  "destSshOpts": ['-i', "/path/to/.ssh/ssh-key"],
  "archiveBaseName": "archive-basename",
  "archiveCommand": "pigz --fast",
  "archiveLinkLatest": true,
  "archiveOwner": "",
  "archivePermissions": "644",
  "archiveKeepDays": 30,
  "backupSrc": "/tests/data/input/",
  "srcSshOpts": [],
  "resources": [
    "test-dir-1",
    "test-dir-2",
    "test-dir-3",
    "test-file-1",
    "test-file-2",
    "test-file-3",
    "test-file-5"
  ],
  "excludes": ["test-dir-2/td2-test-file-1", "test-dir-2/td2-test-file-3"]
}
```

```
# restore-ssh-to-local-example.json
{
  "restoreSrc": "ssh://user@backup-host/tests/output/backups/latest",
  "srcSshOpts": ['-i', "/path/to/.ssh/ssh-key"],
  "restoreDest": "/tests/output/restore/",
  "destSshOpts": [],
  "restoreResources": [
    "test-dir-1",
    "test-dir-2",
    "test-file-1",
    "test-file-2",
    "test-file-3"
  ],
  "excludes": ["*/td2-test-file-2"]
}
```

# Support BBT

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A74VYT1)
