# Sync Code

```shell
brew install hudochenkov/sshpass/sshpass

rsync -aztH --exclude .git --exclude .idea --exclude '*.log' --exclude '__pycache__' --delete --progress --rsh='sshpass -p ssh_pwd ssh -o StrictHostKeyChecking=no -l ssh_user -p ssh_port' . ssh_ip:folder
```
