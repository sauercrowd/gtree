# gtree

An simple convention based, auto-complete enabled helper to deal with git worktrees.

bash and zsh compatible.

## Standard workflow
```bash
jonas@ente:~/git/my-repo$ gtree add my-feature
jonas@ente:~/.gtree/trees/my-repo/my-feature$ claude
jonas@ente:~/.gtree/trees/my-repo/my-feature$ git commit -am "my changes"
jonas@ente:~/.gtree/trees/my-repo/my-feature$ gtree packup
jonas@ente:~/git/my-repo$ git branch
* main
  my-feature
```

## Usage

```sh
gtree add <branch>   # create/add a worktree in $GTREE_DIR
gtree rm <branch>    # remove the worktree for <branch>
gtree cd [branch]    # print/cd to worktree (or main repo if omitted)
gtree packup [-f] [-c] # remove worktree directory and return to main repo. -c to immediately checkout worktree branch. -f to ignore untracked changes in worktree dir
gtree ls             # list worktrees under $GTREE_DIR
```


git packup deletes the worktree and changes back to the main repo. With `gtree packup -c` you can optionally immediately check out the worktree branch

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
