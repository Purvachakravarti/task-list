# do not modify
eval "$(ssh-agent -s)"
ssh-add /home/www-data/.ssh/id_rsa
git fetch
git pull