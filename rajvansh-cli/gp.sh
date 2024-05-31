RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -n "Enter Commit (D- audit fixes & changes): "
read commit_msg

echo -n "Enter Branch (D- main): "
read push_branch

if [ -z "$commit_msg" ]; then
  commit_msg="update: audit fixes & changes"
fi

if [ -z "$push_branch" ]; then
  push_branch="main"
fi

echo ""
echo -e "Using git commit message: ${GREEN}$commit_msg${RESET}"
echo "Using git push branch: ${RED}$push_branch${RESET}"
echo ""

# git commands:
git add .
git status
git commit -m "$commit_msg"
git push origin "$push_branch"

# end of the document