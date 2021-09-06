
### Contribute

**Great you have arrived stumbled upon here**

First, learn the commands used:

* Intrinsic
  * bash, tor
* GNU utilities:
  * set, cat, ls, printf, sed, awk, cut, cp, mv, rm, tee, tar, mkdir, chown, chmod,
* Shell keywords (bash):
  * if then elif else fi, while, for, case esac, do done, function
* Installed via package manager:
  * git, qrencode, openssl, basez

Second, fork this upstream repo, clone your fork, create a new branch and edit your changes there:

```sh
git clone https://github.com/<YOUR_USERNAME>/onion-cli.git
cd onion-cli https://github.com/nyxnor/onion-cli.git
git checkout main
git checkout -b <NEW_BRANCH>
git add <FILE_EDITED>
git commit -m "This changes does this thing"
git push -u origin <NEW_BRANCH>
```

After changes are finished, test thoroughly to see if it works.
If it does and is valuable to the upstream project, first open an issue to be this discussed, after it is evaluated, create a pull request based on your `NEW_BRANCH` and wait for review.