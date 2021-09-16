
# Contribute

**Great you have arrived stumbled upon here**

This project is not perfect and never will be, don't be afraid to correct anyone with you spot something wrong or that can be improved.

## Learn the commands used:

* Intrinsic
  * bash, tor
* GNU utilities:
  * set, cat, ls, printf, sed, awk, cut, cp, mv, rm, tee, tar, mkdir, chown, chmod,
* Shell keywords (bash):
  * if then elif else fi, while, for, case esac, do done, function, basename, realpath
* Extras:
  * git, qrencode, openssl, basez

## Fork, this is FOSS

Fork upstream repo, clone your fork, create a new branch and edit your changes there:

### Fork

Choose one of these options:

Github.com:
1. Go to https://github.com/nyxnor/onionservice.
2. In the top-right corner of the page, click Fork.

GitHub CLI:
```sh
gh repo fork https://github.com/nyxnor/onionservice
```

### Changes

Clone, edit, commit:
```sh
git clone https://github.com/<YOUR_USERNAME>/onionservice.git
cd onionservice
git remote add upstream https://github.com/nyxnor/onionservice.git
git checkout -b <NEW_BRANCH> upstream/<BASE_BRANCH>
git add <FILE_EDITED>
git rm <FILE_DETELED>
git commit -m "This changes does this thing"
git push -u origin <NEW_BRANCH>
```

After changes are finished, test thoroughly to see if it works.
If it does and is valuable to the upstream project, first open an issue to be this discussed, after it is evaluated, create a pull request based on your `NEW_BRANCH` and wait for review.


## Shell syntax

Must be the most efficient (fastest, least consumed resources).
Less commands invoked and the lighter they are (following their use case for performance).

Inefficient:
```sh
cat file | grep pattern
```

Efficient:
```sh
grep pattern file
```

### Study

Resources:
* [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible) - POSIX compliant for CLI.
* [pure-bash-bible](https://github.com/dylanaraps/pure-bash-bible) - BASHISM for the TUI.
* [KISS](https://www.youtube.com/watch?v=EFMD7Usflbg) - Keep It Simple Stupid, but in audio and video format.

#### Confessions

The project understand that using `ls` is not the best way to check if file or folder exists and their names, but we have not found a way to circumvent that as `DataDir` is owned by the tor user (and should stay like that), not by your normal login user. This is way checking with `-d DIR` or ` -f FILE` won't work.

### Check

Run [shellcheck](https://github.com/koalaman/shellcheck) before commiting your changes, it should have no output.
Shellcheck Cdes that can be safely ingored:

* 1090
  * Warn: Can't follow non-constant source. Use a directive to specify location.
  * Case: `source "$(dirname "${0}")"/script`. You sould have to configure `.shellcheckrc` and set `source=/path/to/sourced/script`, which is uncessary in this case. Run shellcheck directly on the sourced script.
* 2236
  * Warn: Use -n instead of ! -z.
  * Case: Does not fit most of the cases because almost no variable is integer, and if it is 0, it already has been handled by another line for that variable to be dismissed (be sure of that).

Run the following to execute shellcheck:
```sh
shellcheck --exclude=1090,2036 onionservice-cli
```

Check if the script it POSIX compliant:
```sh
shellcheck onionservice-cli --exclude=1090,2236 -s sh
```