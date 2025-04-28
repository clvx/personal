+++
author = "Luis Michael Ibarra"
title = "Development Workflow based on Kubernetes Service Mesh"
date = "2025-04-28"
tags = [
    "kubernetes",
    "service-mesh",
    "istio",
    "linkerd",
    "devenv",
    "mirrord",
]
+++

This post is inspired from a lot of conversations with an ex-colleague a couple of 
years back and were resurrected by the [mirrord project](https://github.com/metalbear-co/mirrord).

> The first thing to understand is I just want to deploy something, hit the ingress 
and get my feature live. SO, WHY IS THIS SO HARD? 

Kubernetes helps a lot with day 2 operations but the development workflow is *very* painful.
For instance, to deploy a new version of a microservice, you need to:

1. Build the image
2. Push the image to a registry
3. Update the k8s objects with context of the new image - at minimum the image tag
4. Wait for the deployment to finish
5. Test the new version
6. Rollback if something goes wrong
7. Repeat the process for each microservice
8. Repeat for each environment (dev, staging, prod)

On top of this you have to add aspects like approvals, release windows, data migrations, 
coordination with QA, waiting for environments to be available, etc. Moreover, 
each team can own several microservices, each microservice can have several versions 
living in its own namespace or in a shared one, and each environment can have 
several versions of the same microservice. To make matters worse, each microservice 
configuration can be generated in multiple ways owned by different teams and tools 
triggered by different pipelines.

So, if a developer wants to just test a small feature but it requires upstream and 
downstream dependencies, either they have to deploy all the related services or 
they have to wait for the release cut and hide the change in feature flags. 
Hold on, they could also **YOLO** the change and hope for the best, but that behavior 
will make you very famous amongst peers (and probably HR).

This is a lot of work, cumbersome and error-prone where I've seen hours wasted 
just integrating stuff.

> Eww, how can we make this better?

The key element is routing traffic to the right version of the service but that 
means **KNOWING** the version of the service you want to test. This is where service meshes
come into play. Service meshes are a way to abstract the networking layer of
microservices and provide a way to manage traffic between them. On top of that, 
they have nice features like mirroring, retries, circuit breaking, etc. 

> You've described a tool but no solution yet

Before jumping to service mesh, let's take a step back and discuss *knowing the version*.

Knowing the version is just a version of your code which should point to a `git ref` and 
then masquerade to `semver` or whatever versioning scheme you want to use. However,
people tend to just include this in the image tag and leave all the configuration 
behind without this critical data.
Furthermore, as many follow trunk-based development, there's a golden path when 
a release cut is made and the code is tagged. *Any variation from this path is
considered a different behavior which is exactly what we want to aim for*.

Again the solution leverages routing but Kubernetes routing is based on labels. 
So, if you have a service with a label `version: 1.0.0` and you want to test a new 
version `1.0.1`, you can just deploy a service with a different name with a new label 
`version: 1.0.1` and then route traffic to the new version.

> That sounds interesting, but doesn't that mean the app needs to be aware of the
inputs and outputs?

Yes and No. Seriously it depends. Some routing can be done at the mesh level, just 
adding routes and rules to the traffic routing object. For instance, 

```
/featureA -> backend1 (version: 1.0.0)
/featureB -> backend1 (version: 1.0.1)
```

or mirroring

```
/featureA -> backend1 (version: 1.0.0) -> backend2 (version: 1.0.1)
```

But in other cases, you must change the code to route to the right version. This is 
where having your code implementing [12 factor principles](https://12factor.net/) comes in handy. You allow 
the app to control inputs and outputs based on envars which allows accepting 
traffic from a different source and connecting to sources outside of the mesh.

```
# golden path
example.com/featureA -> backend1 (version: 1.0.0) -> middleware (version: 1.0.0) ->  backend2 (version: 1.0.0)

# here backend1 could have a CORS rule to allow traffic from example.org and 
connects to the externalDB using the stable middleware 
example.org/featureB -> backend1 (version: 1.0.1)  -> middleware (version: 1.0.0) -> externalDB
```

So, if your app expects a specific domain name, you can just set the envar 
to a different one in the new version and add that hostname to the routing rules.
Same if you need to connect to a different backend or database.

> This doesn't sound like a solution, just regular k8s stuff

Yes, but now we can avoid replicating all the related services which can have 
inconsistent data or no data access but as we are relying on the golden path and 
just deviating from it, we have access to the current release allowing us to be
in and out of the expected behavior without following the release cycle. 

Users can test different behaviors without affecting the current release as long 
as they also isolate the data.

More importantly, you now have the ability to replicate your production namespace 
layout which often means also your network layout in lower environments 
simplifying your configuration files.

I mean if you truly think about it, you can also do this straight in prod and it 
will work but I don't encourage this.

> Now I get it, but what about mirrord?

Mirrord is a tool that allows you to run your code locally and connect to
a remote Kubernetes cluster. It does exactly what I just described with the addition of
having a tunnel that can route through the public internet and run it in non 
service meshed environments. It's not a service mesh but it acts like it in a way.

In my opinion, this feature should and must come built-in in the different service 
meshes. They already have the control and data plane. They are battle tested and 
they get injected by default. It just lacks a way to add a service outside the cluster 
through a tunnel which I wouldn't be surprised they support it, I just haven't seen it yet.
