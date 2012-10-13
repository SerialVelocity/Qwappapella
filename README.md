# Please put this in your .git/hooks/pre-commit file and make it executable!

```sh
#!/bin/sh
#

# A git hook script to find and fix trailing whitespace
# in your commits. Bypass it with the --no-verify option
# to git-commit
#

if git-rev-parse --verify HEAD >/dev/null 2>&1 ; then
  against=HEAD
else
  # Initial commit: diff against an empty tree object
  against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi
# Find files with trailing whitespace
for FILE in `exec git diff-index --cached $against -- | cut -f 2- | uniq` ; do
  # Fix them!
  (sed -i 's/[[:space:]]*$//' "$FILE" > /dev/null 2>&1 || sed -i '' -E 's/[[:space:]]*$//' "$FILE")
  git add "$FILE"
done

# Now we can commit
exit
```