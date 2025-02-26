+++
author = "Luis Michael Ibarra"
title = "Migrating Nextcloud to NixOS"
date = "2025-02-26"
tags = [
    "NixOS",
    "nextcloud",
    "certbot",
    "acme",
    "agenix",
]
+++

I've been using Nextcloud for a while now and I've been happy with it. At first I had 
a custom Kubernetes set up defined using plain yaml managed by FluxCD in Digital 
Ocean with a managed postgres and using Digital Ocean Spaces. That worked fine 
for a while but Nextcloud heavily relies in its state and it sucks bad as a cloud 
native application.

## Cloud Native headaches

1. Plugins cannot be loaded declaratively. This is a big one as it makes the 
   application very monolithic and hard to maintain. It forces you to do 
   things manually and cannot let you have a reproducible instance. On top of this, 
   any plugin will live in the nextcloud data directory which is managed at runtime.
   After that you have to use occ.

2. Even though config.php allows injecting environment variables, not all the 
   options can be injected. It has improved over time because I recall mounting 
   empty dirs as init containers to just mount the right php files to make it 
   cloud native. Absolutely nuts. It's still a mess though.

3. Upgrades and maintenance means attaching to a pod and running occ commands. 
   I don't mind this much as it can be automated but holy f*ck, if you have a 
   mounted volume that you want to share with the nextcloud process, it becomes a 
   brain teaser. I had to use a sidecar to make it work and fix user perms.

4. The lack of a reliable kubernetes operator. For the time I spent using Nextcloud 
   on Kubernetes I should've written it. I feel many occ operations could've been 
   managed well with an operator that allowed execute maintenance tasks declarative.


All these points pushed me away of using in Kuberentes. It was way too much hassle. 
The problem wasn't Kubernetes but it's designed entirely monolitich which is totally 
reasonable btw. I was just pushing the boundaries of the system.

## Nextcloud deployments and NixOS to the rescue

To be completely fair it works nice when you deploy it as a standalone in a server, 
but the heavy lifting is quite a bit. It's not only Nextcloud but associated services like 
database, reverse proxy, cache, etc. This is why they have a [all-in-one](https://hub.docker.com/r/nextcloud/all-in-one) docker solution 
but it still faces some of the same challenges as previously mentioned. THe whole 
gist is having something declarative and reproducible. 

Instead of going the path of configuration management which ends up with configuration 
drift plus manual corrections, I decided my mental health doesn't deserve that and 
opted to try it with NixOS. 
**How bad could it be, right?**... _spoiler alert: actually not bad at all_.

### Nextcloud NixOS objectives

So, before jumping on this bs on having Nextcloud again. I decided I wanted:

- The system in a declarative manner. 

- Being able to have the reverse proxy, cache, etc without a hassle.

- Being able to use it locally and externally.

- Being able to stay away from cloud native like avoiding managing volumes, init 
  containers, configmaps, ingresses, attaching to containers, etc.

- Being able to use it under IPv6.

- Being able to manage it as a standalone server.

#### NixOS

I used the Nextcloud package from nixpkgs with pretty much default configurations.
This surprisingly worked without issues. Then, I tweaked a few things for my own 
taste but not much. Plugins are declared and added at build time. Auto updates 
happen under the hood for the plugins but Nextcloud is locked to the current version 
of nixpkgs. You have to change each version at the time so migrations happens 
safely hoping for the best. Pretty much the same process as with a container.

#### IPv6 and routing

I use Starlink because I live closer to bisons, elk and bears than people, so that 
gives me a global /64 IPv6 address which I expose using a Mikrotik hap ax3. Then, 
serve it using nginx forcing TLS.

#### Secrets and Agenix

Security can be tricky in NixOS as the `/nix/store` is world readable. So, 
any secrets that get built would be decrypted and placed in plain text there for 
**everyone**. A few ways to avoid this is using *sops-nix* or *agenix* which allows keeping 
secrets encrypted in the nix store. However, secrets are not something you rollback 
on, so *sops-nix* isn't something I'm comfortable with. I'd rather use *agenix* as you 
have the encrypted files definition included in the configuration but you can 
ALWAYS rotate the secret editing the *age* files after they've been built. This 
allows me loading the nextcloud admin pass, some api keys and other things.

One little annoying thing about *agenix* is you need to add the *owner* and *mode* so 
the other processes can access the secrets when they are decrypted in `/run/agenix`. 
Yeah, this sounds reasonable but the NixOS wiki nor the github project has this info.
Not difficult to figure it out but annoying for sure.

#### Agenix, Acme and Nginx

This is the part it got a little annoying. There's a chicken and egg problem.

As I use a *letsencrypt* certificate generated by a DNS challenge, it needs to be 
readable by the *nginx* and *acme* process. So, if your *nginx* metadata (user, groups, etc) 
hasn't been previously provisioned then the *acme* process cannot generate the 
certificate because the *nginx group* doesn't exist. - *yeah you could create steps to 
validate this* but that's not too declarative for my taste.
I haven't quite tested this behavior fully but I bet there's an option or flow that 
I'm missing.

### Nginx: enableAcme and acmeRoot

So, if you enableAcme in Nginx, it expectes doing a *http-01* challenge but if 
*dns* challenge is what you are doing as I did, then you need `acmeRoot = null` as that's 
how you tell *lego* - *certbot's library* to use the right challenge.

## Thoughts 

Assuming you are comfortable with Nix and NixOS, comparing this configuration to 
whatever the mental puzzle you have to do using on a cloud native setup is a 
relief.

I'm looking forward to the new pain points but it's definitely an improvement so far. 
