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
