bbtcli - Better Backup Tool Command Line Interface

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
```

# Support BBT

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A74VYT1)

# Screenshots

![not yet](/../screenshot/screenshot.gif?raw=true "sceenshot")
