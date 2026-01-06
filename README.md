# gtree

An simple convention based, auto-complete enabled helper to deal with git worktrees.

For bash/zsh.

## Usage

```sh
gtree add <branch>   # create/add a worktree in $GTREE_DIR
gtree rm <branch>    # remove the worktree for <branch>
gtree cd [branch]    # print/cd to worktree (or main repo if omitted)
gtree packup [-f]    # move from worktree back to main repo on the branch, remove worktree directory and checkout worktree branch
gtree ls             # list worktrees under $GTREE_DIR
```

## Standard workflow
1. `gtree add my-branch`:  will use (or create if not yet exist) the branch for a new worktree in a default directory, and cd there
2. do your work, commit what you like
3. `gtree packup`: delete worktree directory, change back to repo location and check out the branch there

If you need to briefly need to jump to your main repo, just use `gtree cd` to get there, and jump back to the worktree with `gtree cd <branch>` (supports auto-complete)

## Install

In a directory that's in your path
```
curl -o gtree https://raw.githubusercontent.com/sauercrowd/gtree/refs/heads/main/gtree
chmod +x gtree
```


In our ~/.profile, add to make `gtree cd` work
```sh
eval "$(gtree init)"
```


## Tests

```sh
./tests/run.sh
```
