# Contribute

This project is not perfect and never will be, contributions are welcome. Don't be afraid to correct anyone with you spot something wrong or that can be improved.

See the open issues and find one to contribute if possible.

First, read the [docs](https://github.com/nyxnor/onionjuggler/tree/main/docs).

## License

Every contribution will licensed accordingly to the [LICENSE](LICENSE), which currently is MIT.

## Shell

### Commands

Currently there are many commands used and there is a constant development to use less commands, focusing on installing less packages.

Commands used by this project:

* [Shell and Utilities volume of POSIX.1-2017 - IEEE Std 1003.1-2017 - ISO/IEC/IEEE 9945:2009](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html):
  * [cat](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cat.html#tag_20_13)
  * [chmod](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/chmod.html#tag_20_17)
  * [chown](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/chown.html#tag_20_18)
  * [cmp](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cmp.html#tag_20_20)
  * [cp](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cp.html#tag_20_24)
  * [cut](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/cut.html#tag_20_28)
  * [date](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/date.html#tag_20_30)
  * [dot](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_18)
  * [env](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/env.html#tag_20_39)
  * [exit](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_21)
  * [export](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_22)
  * [grep](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/grep.html#tag_20_55)
  * [id](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/id.html#tag_20_59)
  * [ln](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ln.html#tag_20_67)
  * [ls](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html#tag_20_73)
  * [man](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/man.html#tag_20_77)
  * [mkdir](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/mkdir.html#tag_20_79)
  * [mv](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/mv.html#tag_20_82)
  * [printf](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html#tag_20_94)
  * [read](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/read.html#tag_20_109)
  * [rm](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/rm.html#tag_20_111)
  * [sed](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sed.html#tag_20_116)
  * [sh](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html#tag_20_117)
  * [sort](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sort.html#tag_20_119)
  * [tail](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tail.html#tag_20_125)
  * [tee](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tee.html#tag_20_127)
  * [tr](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tr.html#tag_20_132)
  * [trap](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28)
  * [tput](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tput.html#tag_20_131)
  * [uniq](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/uniq.html#tag_20_144)
  * [vi](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/vi.html#tag_20_152)

* Installation:
  * Pre-configured (won't be installed by the project):
    * [sudo](https://www.sudo.ws/docs/man/1.9.8/sudo.conf.man/)/[doas](https://man.openbsd.org/doas.conf.5)
  * Required:
    * [tor](https://github.com/torproject/tor/blob/main/doc/man/tor.1.txt)
    * [tar](https://linux.die.net/man/1/tar)
    * [openssl](https://www.openssl.org/docs/manmaster/man1/genpkey.html)
    * [basez](http://www.quarkline.net/basez/)
    * [git](https://git-scm.com/docs/user-manual)
    * [python3-stem](https://stem.torproject.org/download.html)
    * [nginx](https://docs.nginx.com/nginx/admin-guide/)/[apache](https://httpd.apache.org/docs/current/)/[openbsd-httpd](https://man.openbsd.org/httpd.8)
    * [dialog](https://invisible-island.net/dialog/manpage/dialog.txt)/[whiptail](https://manpages.debian.org/testing/whiptail/whiptail.1.en.html)
  * Optional:
    * [(lib)qrencode](https://github.com/fukuchi/libqrencode)
  * Development:
    * [pandoc](https://pandoc.org/MANUAL.html)
    * [shellcheck](https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md)

### Builtins

The project will never be pure POSIX alternative to external process such as git, grep, openssl, but it aims to use more of the shell capabilities than depending on more packages. Read the [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible), a POSIX compliant and efficiency guide, less commands to install, more portable it becomes. Prefer builtins alternatives to external process, then shell builtin, after that commands/packages available on *nix systems that have similar options.

Shell builtins are preferred. To find all builtins:
* Download shellspec builtins script:
```sh
curl --tlsv1.3 --proto =https --location -o /tmp/builtins.sh https://raw.githubusercontent.com/shellspec/shellspec/master/contrib/builtins.sh
#wget --https-only -P /tmp/ https://raw.githubusercontent.com/shellspec/shellspec/master/contrib/builtins.sh
sh /tmp/builtins.sh
```

### External commands limitations

Operating system extensions (GNU extesions on commands such as grep) and commands unique to some unix operating systems but not present on others need to be avoided. If you still need to use external commands, check their POSIX manual, mentioned on [commands](#commands).

### Syntax

* Identation is 2.
* Lines that begin with "## " try to explain what's going on. Lines that begin with just "#" are disabled commands.
* Sacrificing some code legibility for speed is acceptable, but if the maintainer considers it messy because it does not help performance, it won't be approved. This is the only subjective requirement.
* Less commands invoked and the lighter they are (following their use case for performance) -> Inefficient: `cat file | grep pattern`, Efficient: `grep pattern file`.
* `printf` instead of `echo` for portability reasons.
* exit codes if no error occurs is `0`, else `1`.
* test managed with `&&` for true and `||` for false.
* `case` instead of `if-then-else` on most of the cases.
* for loops using command instead of variables for the Z SHell -> `for ITEM in $(command)`.
* variables should be reffered with brackets `{}` and double quotes `""`, resulting in `"${var}"`.
* unquoted variabes are for commands that need to expand, disable SC2086 as a directive in this case one line before the occurence -> `# shellcheck disable=SC2086`
* the project variables are lower case and if there are two or more words, separated by `_` (underscore) -> `$var_onion`
* environmental variables are upper case letters -> `$VAR`.
* variable values must be quoted -> `var="something"`.
* for the rest, follow the same pattern predominant in the scripts.

### Check

Run [shellcheck](https://github.com/koalaman/shellcheck) before commiting your changes, it should have no output.

Some checks are not needed for certain files and are cherry picked to be disabled. It is recommended to check before every commit:

```sh
./configure.sh -r
```

**Shellcheck Codes**:
* Global: specify on [.shellcheckrc](https://github.com/koalaman/shellcheck/wiki/Ignore#ignoring-one-or-more-type-of-error-forever).
* Applicable to the entire file: [specify the line after the shebang](https://github.com/koalaman/shellcheck/wiki/Ignore#ignoring-one-specific-instance-in-a-file)
* Applicable to certain lines: [specify on the line above the occurence](https://github.com/koalaman/shellcheck/wiki/Ignore#ignoring-all-instances-in-a-file-044)

Some pitfalls can occur when writing that shellcheck won't recognize, as it doesn't warn about [SC2045](https://github.com/koalaman/shellcheck/wiki/SC2045), even though it should (we need to find a way to circumvent that as `DataDir` is owned by the tor user, not by your normal login user. This is way checking with `-d DIR` or ` -f FILE` doesn't work. A possiblle solution is `"${su_cmd}" -u "${tor_user} find ${tor_data_dir_services} -maxdepth 1 -type d | tail -n +2`)

Read [Bash Pitfalls](http://mywiki.wooledge.org/BashPitfalls) (some rules are applicable to POSIX shells).

## Documentation

Not only code is important, making it understandable by anyone who reads the documentation is relevant, improve the docs, spell mistakes, better wording.

## Issues

Help with open issues by responding in details to the author.

Maintainers/Collaborators:
* Before closing any issue, explain the reason for that actions, which can be:
  * lack of respone to the latest comment after 7 (seven days).
  * no longer relevant to the current code base.
  * if the issue won't be fixed.

## Commits

Fork the repository [here](https://github.com/nyxnor/onionjuggler/fork)

Clone:
```sh
git clone https://github.com/<YOUR_USERNAME>/onionjuggler.git
cd onionjuggler
```

Create feature or fix branch based on the upstream project development branch as base:
```sh
git remote add upstream https://github.com/nyxnor/onionjuggler.git
git checkout -b <NEW_BRANCH> upstream/<BASE_BRANCH>
```

After changes are finished, test thoroughly to see if it works.
If it does and is valuable to the upstream project, first open an issue to be this discussed, after it is evaluated, create a merge request.

Before commiting, shellcheck with:
```sh
./configure.sh -r
```

Commit to your branch:
```sh
git add <FILE_EDITED>
git rm <FILE_DETELED>
git commit -m "Title with short description" -m "Detailed description of the changes"
git push -u origin <NEW_BRANCH>
```

Open a pull request on GitHub and compare it against the `upstream/<BASE_BRANCH>`.

## Pull Requests

Help with pull requests by reviewing it.

Regarding reviewing pull requests, the vocabulary is:
* **cACK** - Concept ACK - Agree with the idea and overall direction, but haven't reviewed the code changes or tested them.
* **utACK** - Untested ACK - Reviewed and agree with the code changes but haven't actually tested them.
* **tACK** - Tested ACK -Reviewed the code changes and have verified the functionality or bug fix.
* **ACK** - A loose ACK can be confusing. It's best to avoid them unless it's a documentation/comment only change in which case there is nothing to test/verify; therefore the tested/untested distinction is not there.
* **NACK** - Not ACK - Disagree with the code changes/concept. Should be accompanied by an explanation.
