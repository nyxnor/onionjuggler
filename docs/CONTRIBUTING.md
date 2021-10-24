# Contribute

This project is not perfect and never will be, contributions are welcome. Don't be afraid to correct anyone with you spot something wrong or that can be improved.

There is a TODO list at the end of the README. Those are tasks that will improve the usability and documentation, the difficulty level ranges a lot, so take what fits you.

First, read the [docs](https://github.com/nyxnor/onionservice/tree/main/docs).

## Shell

It must be POSIX compliant. The [Shellcheck Code 2039](https://github.com/koalaman/shellcheck/wiki/SC2039) must not be ignored.
Read [Shell & Utilities: Detailed Toc](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)

OnionService uses shell built-in commands and some basic [POSIX-compliant commands](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html) to support wide range of environments.

* Builtins:
	* [dot](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_18)
	* [exit](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_21)
	* [export](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_22)
	* [trap](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28)
	* [printf](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html#tag_20_94)
	* [pwd](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/pwd.html#tag_20_97)
	* [read](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/read.html#tag_20_109)

* Not builtins:
	* [awk](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html#tag_20_06)
	* [cat](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cat.html#tag_20_13)
	* [chmod](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/chmod.html#tag_20_17)
	* [chown](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/chown.html#tag_20_18)
	* [cp](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cp.html#tag_20_24)
	* [cut](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cut.html#tag_20_28)
	* [date](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/date.html#tag_20_30)
	* [grep](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/grep.html#tag_20_55)
	* [ln](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ln.html#tag_20_67)
	* [ls](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html#tag_20_73)
	* [man](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/man.html#tag_20_77)
	* [mkdir](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/mkdir.html#tag_20_79)
	* [mv](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/mv.html#tag_20_82)
	* [rm](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/rm.html#tag_20_111)
	* [sed](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sed.html#tag_20_116)
	* [sh](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html#tag_20_117)
	* [sort](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sort.html#tag_20_119)
	* [tail](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tail.html#tag_20_125)
	* [tee](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tee.html#tag_20_127)
	* [touch](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/touch.html#tag_20_130)
	* [tr](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tr.html#tag_20_132)
	* [uniq](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/uniq.html#tag_20_144)
	* [vi](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/vi.html#tag_20_152)
	* [wc](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/wc.html#tag_20_154)

### Builtins

The project will never be pure POSIX alternative to external process such as git, grep, openssl, but it aims to use more of the shell capabilities than depending on more packages. Read the [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible) - POSIX compliant and efficiency guide while listening to [KISS](https://www.youtube.com/watch?v=EFMD7Usflbg) - Keep It Simple Stupid, but in audio and video format.

Less commands to install, more portable it becomes. Prefer [pure-sh](https://github.com/dylanaraps/pure-sh-bible) alternatives to external process, then shell builtin, after that commands/packages available on *nix systems that have similar options.

Shell builtins are preferred. To find all builtins:
1. Download shellspec builtins script:
```sh
curl -o /tmp/builtins.sh https://raw.githubusercontent.com/shellspec/shellspec/master/contrib/builtins.sh
# or
wget -P /tmp/ https://raw.githubusercontent.com/shellspec/shellspec/master/contrib/builtins.sh
```
1. Run it with `sh`:
```sh
sh /tmp/builtins.sh
```

### External commands limitations

Operating system extensions (GNU extesions on commands such as grep) and commands unique to some unix operating systems but not present on others need to be avoided. If you still need to use external commands, check their POSIX manual, for example:
* [grep](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/grep.html#tag_20_55)
* [sed](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sed.html#tag_20_116)

Check [requirements](README#requirements) to see the listed commands used on the project and their respective manual.

### Syntax

1. Identation is 2.
1. Lines that begin with "## " try to explain what's going on. Lines that begin with just "#" are disabled commands.
1. Sacrificing some code legibility for speed is acceptable, but if the maintainer considers it messy because it does not help performance, it won't be approved. This is the only subjective requirement.
1. The most efficient (fastest, least consumed resources). Less commands invoked and the lighter they are (following their use case for performance) -> Inefficient: `cat file | grep pattern`, Efficient: `grep pattern file`.
1. variable paths should not end with "/".
1. `printf` instead of `echo` for portability reasons.
1. for the rest, follow the same pattern predominant in the scripts.
1. for loops using command instead of variables for the Z SHell -> `for ITEM in $(command)`.
1. exit codes -> `&&` for true or 0 and `||` for false or 0.
1. `case` instead of `if-then-else`
1. variables on upper case letters -> `VAR=`.
1. variable values must be quoted -> `VAR="something"`.
1. use brackes on variables to avoid some tiny errors -> `${VAR}`.
1. quote every variable if they are not supposed to expand -> `"${VAR}"`.
1. quote every command that are not supposed to expand -> `"$(command)"`

### Check

Run [shellcheck](https://github.com/koalaman/shellcheck) before commiting your changes, it should have no output.

Some checks are not needed for certain files and are cherry picked to be disabled. It is recommended to check before every commit:

```sh
sh setup.sh check
```

Shellcheck Codes that can be safely ingored:

* SC1090
  * Warn: Can't follow non-constant source. Use a directive to specify location.
  * Case: The source path is a variable (ONIONSERVICE_PWD). Because of that, use `# shellcheck source=/dev/null`.
* SC2086
  * Warn: Double quote to prevent globbing and word splitting.
  * Case: some variables need to expand, remove this for verification
* SC2034
  * Warn: unused vars
  * Case: only for the `.onionrc` because the variables are not used there

### Fork the repository

Choose one of these options:

1. Github.com: Go to https://github.com/nyxnor/onionservice an in the top-right corner of the page, click Fork.

1. or on GitHub CLI:
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
```git
git remote add upstream https://github.com/nyxnor/onionservice.git
git checkout -b <NEW_BRANCH> upstream/<BASE_BRANCH>
```

After making changes, it is recommended to shellcheck with the predefined arguments:
```sh
sh setup.sh check
```

#### Commit

After changes are finished, test thoroughly to see if it works.
If it does and is valuable to the upstream project, first open an issue to be this discussed, after it is evaluated, create a merge request.

Before commiting, shellcheck and empty `ONIONSERVICE_PWD`
```sh
sh setup.sh release
```

Commit to your branch
```git
git add <FILE_EDITED>
git rm <FILE_DETELED>
git commit -m "These changes does this thing"
git push -u origin <NEW_BRANCH>
```

Open a pull request on GitHub and compare it against the `upstream/<BASE_BRANCH>`.

## Confessions

The project understand that using `ls` is not the best way to check if file or folder exists and their names, but still needs to find a way to circumvent that as `DataDir` is owned by the tor user (and should stay like that), not by your normal login user. This is way checking with `-d DIR` or ` -f FILE` won't work. The `find` command can be used with `-maxdepth=1` if it does not shown the
