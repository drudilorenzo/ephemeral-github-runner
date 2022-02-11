#!/bin/bash

sh -c 'cat <<EOF> /etc/systemd/system/ghrunner-reg.service
[Unit]
Description=Register GitHub Runner

[Service]
User=ghrunner
Type=oneshot
WorkingDirectory=/home/ghrunner/workdir/actions-runner
TasksMax=100%
LimitCPU=infinity
LimitMEMLOCK=infinity
SyslogIdentifier=ghrunner-reg
ExecStartPre=-/bin/bash -c "/home/ghrunner/workdir/actions-runner/config.sh --url https://github.com/{{{repo}}} \
    --token {{token}} \
    --name {{ghRunnerName}}-'$(/usr/bin/echo $RANDOM)' \
    --work _work \
    --runnergroup default \
    --labels cuda \
    --runasservice \
    --ephemeral"
ExecStart=-/bin/bash -c "/home/ghrunner/workdir/actions-runner/run.sh"

[Install]
WantedBy=multi-user.target
EOF'

sh -c 'cat <<EOF> /etc/systemd/system/ghrunner-dereg.service
[Unit]
Description=Deregister GitHub Runner
DefaultDependencies=no
Before=shutdown.target

[Service]
User=ghrunner
Type=oneshot
WorkingDirectory=/home/ghrunner/workdir/actions-runner
ExecStart=/bin/bash -c "/home/ghrunner/workdir/actions-runner/config.sh remove --token {{token}}"
TimeoutStartSec=0

[Install]
WantedBy=shutdown.target
EOF'

sudo systemctl daemon-reload
sudo systemctl start ghrunner-reg.service