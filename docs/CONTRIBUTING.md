# Contribute

This project is not perfect and never will be, contributions are welcome. Don't be afraid to correct anyone with you spot something wrong or that can be improved.

There is a TODO list at the end of the README. Those are tasks that will improve the usability and documentation, the difficulty level ranges a lot, so take what fits you.

## Shell

All executables are shellscripts and will stay that way till the limit.

### Study

Resources:
* [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible) - POSIX compliant and efficiency guide.
* [KISS](https://www.youtube.com/watch?v=EFMD7Usflbg) - Keep It Simple Stupid, but in audio and video format.

### Syntax

These are requirements and must be done. If not conformed, the merge request must not be accepted.

1. Sacrificing some code legibility for speed is acceptable, but if the maintainer considers it messy because it does not help performance, it won't be approved. This is the only subjective requirements

1. POSIX compliant. The [SCC2039](https://github.com/koalaman/shellcheck/wiki/SC2039) must not be ignored

1. The most efficient (fastest, least consumed resources). Less commands invoked and the lighter they are (following their use case for performance) -> Inefficient: `cat file | grep pattern`, Efficient: `grep pattern file`.

1. `printf` instead of `echo` for portability reasons.

### Check

Run [shellcheck](https://github.com/koalaman/shellcheck) before commiting your changes, it should have no output.

Some checks are not needed for certain files and are cherry picked to be disabled. It is recommended to check before every commit:

```sh
sh setup.sh check
```

Shellcheck Codes that can be safely ingored:

* SC1090
  * Warn: Can't follow non-constant source. Use a directive to specify location.
  * Case: The source path is a variable (ONIONSERVICE_PWD). You sould have to configure `.shellcheckrc` and set `source=/path/to/sourced/script`, which is uncessary in this case. Run shellcheck directly on the sourced script, which is `.onionrc`.
* SC2086
  * Warn: Double quote to prevent globbing and word splitting.
  * Case: some variables need to expand, remove this for verification
* SC2034
  * Warn: unused vars
  * Case: only for the `.onionrc` because the variables are not used there
* SC2236
  * Warn: Use -n instead of ! -z.
  * Case: Does not fit most of the cases because almost no variable is integer, and if it is 0, it already has been handled by another line for that variable to be dismissed (be sure of that).

### Fork the repository

Choose one of these options:

1. Github.com:
1. 1. Go to https://github.com/nyxnor/onionservice.
1. 2. In the top-right corner of the page, click Fork.

2. GitHub CLI:
```sh
gh repo fork https://github.com/nyxnor/onionservice
```

### Changes

#### Basic instructions

Clone:
```sh
git clone https://github.com/<YOUR_USERNAME>/onionservice.git
cd onionservice
```

Create feature or fix branch based on the upstream project development branch as base:
```
git remote add upstream https://github.com/nyxnor/onionservice.git
git checkout -b <NEW_BRANCH> upstream/<BASE_BRANCH>
```

After making changes, it is recommended to shellcheck with the predefined arguments:
```sh
sh setup.sh check
```

#### Commit

After changes are finished, test thoroughly to see if it works.
If it does and is valuable to the upstream project, first open an issue to be this discussed, after it is evaluated, create a pull request and for review.

Before commiting, shellcheck and empty `ONIONSERVICE_PWD`
```sh
sh setup.sh release
```

Commit
```
git add <FILE_EDITED>
git rm <FILE_DETELED>
git commit -m "These changes does this thing"
git push -u origin <NEW_BRANCH>
```

## Confessions

The project understand that using `ls` is not the best way to check if file or folder exists and their names, but still needs to find a way to circumvent that as `DataDir` is owned by the tor user (and should stay like that), not by your normal login user. This is way checking with `-d DIR` or ` -f FILE` won't work. The `find` command can be used with `-maxdepth=1` if it does not shown the