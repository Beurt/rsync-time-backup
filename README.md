# rsync-time-backup
A simple script to backup a directory with rsync and hardlinks, inspired by Backintime

This script is mainly inspired by Backintime (https://github.com/bit-team/backintime), but is a mix between two other scripts (https://netfuture.ch/2013/08/simple-versioned-timemachine-like-backup-using-rsync/ and https://github.com/samdoran/rsync-time-machine)


## How to get up and running

Just copy [rsync-time-backup.sh](https://raw.githubusercontent.com/Beurt/rsync-time-backup/master/rsync-time-backup.sh) to your machine.

Then launch `rsync-time-backup.sh`:

```shell
rsync-time-backup.sh /path/to/source /path/to/dest name_of_the_backup
```

Where `/path/to/source` is the path of the source **directory** you want to backup. `/path/to/dest` is the path to the destination directory where you want to save your data. `name_of_the_backup` is the name of the backup directory you want. You may use something like ``date +%Y-%m-%d-%H%M%S`` or a plain name.

## What it does

`rsync-time-backup.sh` is making versionned backup. It means that each backup is compared to the previous one in order to save only the files that are changed. Therefore, each backup directory contains the whole backup with all the files. The trick is that unchanged files are hardlinks of the previous backup files.
To do that, `rsync-time-backup.sh` uses built-in `rsync` hardlinks feature `--link-dest`.

Step by step, here is what the script is doing:

- first checks with the lock file in `/path/to/dest` if a backup is not already going on
- then checks if an abandoned backup is not already existing in `/path/to/dest` directory. If yes it starts again from here.
- If it is a fresh backup, creates a temp directory (named `__backup_in_progress`) and a lock file in the `/path/to/dest`
- Then start `rsync` with `--link-dest` to the previous backup directory. Meaning every time a file has not changed, `rsync` will create a hardlink in `/path/to/dest` instead of copying it again (and wasting space). **Please note that `rsync` is done with `-c` option which performs a checksum verification.** *Cons*: it takes a more time and CPU. *Pros*: while using hardlinks it is safer (we never know if the original inode has been altered).
- Then renames the temp directory `__backup_in_progress` to the directory name you have chosen `name_of_the_backup` (In case of name collision, a timestamp is added to the directory name)
- creates a simlink to this very new snapshot named `__latest_backup` (will be used in the next backup as source for comparison)
- remove lock file and temp folder.

In your backup directory `/path/to/dest` you may end up with something like that:

```bash
sh:# du -sch ./
381G    2017-04-30
100M    2017-05-01
100M    2017-05-01---2017-05-01-115305
100M    2017-05-03
0       __latest_backup
381G    total
```
Each snapshot directory contains the whole files and directories of the backup, but as you see, using just the space of the changed files.

You can run the script periodically to make safe backups. For instance, to keep an archive of monthly backups forever, put this in your monthly crontab:

```bash
#!/bin/sh
/usr/local/bin/rsync-time-backup.sh /path/to/source /path/to/dest `date +%Y-%m-%d`
```
See https://netfuture.ch/2013/08/simple-versioned-timemachine-like-backup-using-rsync/ for more details.

Currently, I'm using it as a `Time Backup` app replacement to backup a Synology NAS.

## License

This piece of software is AGPL (https://www.gnu.org/licenses/agpl-3.0.html)

Some bits of the code and ideas came from Sam Doran (https://github.com/samdoran/rsync-time-machine) with the following license



> Copyright (c) 2013 Sam Doran
>
>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
>The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Finally, main ideas and code came from:  https://netfuture.ch/2013/08/simple-versioned-timemachine-like-backup-using-rsync and was mainly inspired by Backintime (https://github.com/bit-team/backintime)
