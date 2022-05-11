set fish_greeting
set TERM "xterm-256color"

function fish_user_key_bindings
  ### fish_vi_key_bindings
  fish_default_key_bindings
end

# must supply a remote url
function git-init --argument git_url
  if echo $git_url | grep -q "git"
    echo $git_url
    git init
    git add .
    git commit -m "Initial Commit"
    git branch -M main
    git remote add origin $argv
    git push -u origin main
  else
    echo "Please provide a github repo url"
  end
end

### VARIOUS functions from https://github.com/razzius/fish-functions
# backup of file to file.bak
function backup --argument filename
    cp $filename $filename.bak
end

# restore a backup
function restore --argument file
    mv $file (echo $file | sed s/.bak//)
end

# a better copy command
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -i -r $from $to
    else
        command cp -i $argv
    end
end

function move
    mv -i $argv
end

# remove with extra functionality
function remove
    set original_args $argv

    argparse r f -- $argv

    if not set -q _flag_r || set -q _flag_f
        rm $original_args
        return
    end

    function confirm-remove --argument dir
        set display_dir (echo $dir | unexpand-home-tilde)

        if confirm "Remove .git directory $display_dir?"
            rm -rf $dir
            return
        end

        echo 'Cancelling.'
        return 1
    end

    for f in $argv
        set gitdirs (find $f -name .git)
        for gitdir in $gitdirs
            confirm-remove $gitdir
        end
    end

    rm $original_args
end

function clean-unzip --argument zipfile
    if not test (echo $zipfile | string sub --start=-4) = .zip
        echo (status function): argument must be a zipfile
        return 1
    end

    if is-clean-zip $zipfile
        unzip $zipfile
    else
        set zipname (echo $zipfile | trim-right '.zip')
        mkdir $zipname || return 1
        unzip $zipfile -d $zipname
    end
end

function word-count
    wc -w | string trim
end

function move-last-download
    mv ~/Downloads/(ls -t -A ~/Downloads/ | head -1) .
end

function wifi-network-name
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print substr($0, index($0, $2))}'
end

function wifi-password
    security find-generic-password -wa (wifi-network-name)
end

function wifi-reset
    networksetup -setairportpower en0 off
    networksetup -setairportpower en0 on
end

function git-commit
    function staged-files-matching-filter --argument filter
        git diff --cached --name-only --diff-filter=$filter | string split0
    end

    function count-files
        awk NF | wc -l | string trim
    end

    if not any-arguments $argv
        set new_files (staged-files-matching-filter A)
        set n_new_files (echo -n "$new_files" | count-files)

        set deleted_files (staged-files-matching-filter D)
        set n_deleted_files (echo -n "$deleted_files" | count-files)

        set updated_files (staged-files-matching-filter M)
        set n_updated_files (echo -n "$updated_files" | count-files)

        set renamed_files (staged-files-matching-filter R)
        set n_renamed_files (echo -n "$renamed_files" | count-files)

        set n_changed_files (math $n_new_files + $n_deleted_files + $n_updated_files + $n_renamed_files)

        switch $n_changed_files
            case 0
                echo "Nothing staged"
            case 1
                if [ $n_new_files = 1 ]
                    git commit -m "Add $new_files"
                else if [ $n_deleted_files = 1 ]
                    git commit -m "Delete $deleted_files"
                else if [ $n_updated_files = 1 ]
                    git commit -m "Update $updated_files"
                else if [ $n_renamed_files = 1 ]
                    git diff --cached --name-status | read _ from to
                    git commit -m "Rename $from to $to"
                end
            case '*'
                echo "Multiple files changes; add a commit message"
        end
    else
        git commit -m (echo $argv)
    end
end

abbr -a rm remove
abbr -a mv move
abbr -a cp copy
abbr -a gc git-commit
abbr -a gi git-init

alias vim="nvim"
alias ls="exa"
alias emacs="emacsclient -c -a 'emacs'"

### bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

bind ! __history_previous_command
bind '$' __history_previous_command_arguments

# set up the same key bindings for insert mode if using fish_vi_key_bindings
if test "$fish_key_bindings" = 'fish_vi_key_bindings'
    bind --mode insert ! __history_previous_command
    bind --mode insert '$' __history_previous_command_arguments
end

function _plugin-bang-bang_uninstall --on-event plugin-bang-bang_uninstall
    bind --erase --all !
    bind --erase --all '$'
    functions --erase _plugin-bang-bang_uninstall
end
### end of bang-bang

### START OF SASHIMI
# name: sashimi
function fish_prompt
  set -l last_status $status
  set -l cyan (set_color -o cyan)
  set -l yellow (set_color -o yellow)
  set -g red (set_color -o red)
  set -g blue (set_color -o blue)
  set -l green (set_color -o green)
  set -g normal (set_color normal)

  set -l ahead (_git_ahead)
  set -g whitespace ' '

  if test $last_status = 0
    set initial_indicator "$green◆"
    set status_indicator "$normal❯$cyan❯$green❯"
  else
    set initial_indicator "$red✖ $last_status"
    set status_indicator "$red❯$red❯$red❯"
  end
  set -l cwd $cyan(basename (prompt_pwd))

  if [ (_git_branch_name) ]

    if test (_git_branch_name) = 'master'
      set -l git_branch (_git_branch_name)
      set git_info "$normal git:($red$git_branch$normal)"
    else
      set -l git_branch (_git_branch_name)
      set git_info "$normal git:($blue$git_branch$normal)"
    end

    if [ (_is_git_dirty) ]
      set -l dirty "$yellow ✗"
      set git_info "$git_info$dirty"
    end
  end

  # Notify if a command took more than 5 minutes
  if [ "$CMD_DURATION" -gt 300000 ]
    echo The last command took (math "$CMD_DURATION/1000") seconds.
  end

  echo -n -s $initial_indicator $whitespace $cwd $git_info $whitespace $ahead $status_indicator $whitespace
end

function _git_ahead
  set -l commits (command git rev-list --left-right '@{upstream}...HEAD' 2>/dev/null)
  if [ $status != 0 ]
    return
  end
  set -l behind (count (for arg in $commits; echo $arg; end | grep '^<'))
  set -l ahead  (count (for arg in $commits; echo $arg; end | grep -v '^<'))
  switch "$ahead $behind"
    case ''     # no upstream
    case '0 0'  # equal to upstream
      return
    case '* 0'  # ahead of upstream
      echo "$blue↑$normal_c$ahead$whitespace"
    case '0 *'  # behind upstream
      echo "$red↓$normal_c$behind$whitespace"
    case '*'    # diverged from upstream
      echo "$blue↑$normal$ahead $red↓$normal_c$behind$whitespace"
  end
end

function _git_branch_name
  echo (command git symbolic-ref HEAD 2>/dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty 2>/dev/null)
end
### END OF SASHIMI


