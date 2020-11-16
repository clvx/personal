+++
author = "Luis Michael Ibarra"
title = "Gitlab Runners"
date = "2020-11-16"
tags = [
    "gitlab",
    "ci",
    "cd",
    "runner",
]
+++

Gitlab Runners are the core component to execute your automation for the Gitlab platform.

## Components

Runners are pretty simple to manage. It consists on a golang binary which is deployed
in a platform which can be a vm, container, etc. A platform can have *one or more 
Gitlab Runners*. Then, a `runner` can have only *one executor* which is the one 
that execute your jobs. An `executor` can be a shell, a docker container, ssh to jump
to another host, or an _orchestrator_ like Kubernetes, VirtualBox, or AWS.

After a `runner` is set up, it needs to be registered in Gitlab using `gitlab-runner register`.
By default a `runner` does not have any tags associated. Tags are important to 
allocate pipeline jobs so they can be executed in runners. 
