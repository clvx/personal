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
draft = true
+++

Gitlab Runners are the core component to execute your automation for the Gitlab platform.

## Concepts

Runners are pretty simple to manage. It consists on a golang binary which is deployed
in a platform which can be a vm, container, etc. A platform can have *one or more 
Gitlab Runners*. Then, a `runner` can have one or more executors, but only *one executor* 
executes your jobs. An `executor` can be a shell, a docker container, ssh to jump
to another host, or an _orchestrator_ like Kubernetes, VirtualBox, or AWS.

## Registration

After a `runner` is set up, it needs to be registered in Gitlab using `gitlab-runner register`.
By default a `runner` does not have any tags associated. Tags are important to 
allocate pipeline jobs so they can be executed in runners.
If a `.gitlab-ci.yml` stage section does not have a tag associated it will not be 
executed as it does not have an executor associated with it. Furthermore, defined 
tags in a stage section must match runner tags. 

For example, If a runner has tags `build, test, deploy` and the stage section defines 
an executor `build`, then that pipeline will be executed in the runner; howver, 
if the stage section defines tags `deploy,release`,  then it will not be executed 
as the runner does not have the `release` tag associated with it.

## Configuration

The main config file for a gitlab-runner is `/etc/gitlab-runner/config.toml`. 
Here you can add runners, configure global environment variables for each runner,
 build and cache dir location, etc.
This is being read every 3 seconds by default, if it encounters a change in the 
common configurations, it will reload the new configs. Configs associated to 
networking and others will require a full service restart.

Environment variables defined in a runner config will be overriden if the envar 
is also defined in the pipeline definition as these variables have precedence 
over the config file.
