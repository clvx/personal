+++
author = "Luis Michael Ibarra"
title = "Nix Generations and Rollbacks"
date = "2024-10-29"
tags = [
    "nix",
    "generations",
    "nixos",
]
+++

One of the coolest features of Nix is the ability to rollback to a previous state. 
This is done by generations.

## Generations

Generations are a way to keep track of the state of the system. Each time a change 
is made to the system, a new generation is created. This allows you to rollback 
to a previous state if something goes wrong.

A generation is a snapshot of the system at a specific point in time. It includes
all the packages that were installed at that time, as well as the configuration
files that were in place.

Generations can be listed in a couple of ways. `nix-env --list-generations` command 
lists the generations for the user profile. `nix-env --list-generations --profile /nix/var/nix/profiles/system` 
lists the generations for the system profile. 

System profile is the profile that is used by the system itself. It is the profile 
that is used when the system boots up. User profile is the profile that is used by
the user. It is the profile that is used when the user logs in.

Generations can be found in `/nix/var/nix/profiles/`. Each stored generation includes
a `system` and `user` profile. The `system` profile is used by the system itself, while
the `user` profile is used by the user.

When using flakes and `nixos-rebuild`, a new generation is created each time the system
configuration is changed. This allows you to rollback to a previous state if something
goes wrong.

## Rollbacks

Rollbacks are the process of reverting to a previous generation. This can be done using
the `nix-env --rollback` command. This command will revert the system to the previous
generation. However, when using flakes and `nixos-rebuild`, the rollback is done using
the `nixos-rebuild switch --rollback` command or checking out the previous and running
`nixos-rebuild switch which I encourage to use.

Rollbacks are useful when something goes wrong with the system configuration. For example,
if a new package is installed that causes the system to crash, you can rollback to the 
previous generation to restore the system to a working state.

Rollbacks are also useful when testing new configurations. If you make a change to the system 
configuration that causes a problem, you can rollback to the previous generation to restore 
the system to a working state. For instance, [installing a particular kernel version to fix 
ip6tables so you can run cilium or tailscale in your ipv6 network](https://github.com/tailscale/tailscale/issues/13863).

/run/current-system/ and /run/booted-system/ are symlinks to the current and booted system 
generations respectively. Both should be the same unless you are in the middle of a system 
rebuild.

A nice way to see the differences between generations is
`diff <(ls -l /run/current-system/ | sort) <(ls -l /run/booted-system/ | sort)` which 
shows the differences between two generations. This can be useful when trying to 
debug a problem with the system configuration. 

## Learnings

### Flakes over nix-env
Use flakes and `nixos-rebuild` for system configuration changes. Use `nix-env` for user 
profile changes. Use `nix-env --rollback` for user profile rollbacks. Avoid using `nixos-rebuild 
switch --rollback` for system profile rollbacks; instead, checkout the previous generation 
and run `nixos-rebuild switch`.

### Pin your commit in your system generation
When using flakes, it is a good idea to pin the commit hash in your system generation.
This will ensure that the system is always built from the same commit, making it easier
to rollback to a previous state if something goes wrong.

You can use the [system.nixos.label](https://github.com/NixOS/nixpkgs/blob/7eee17a8a5868ecf596bbb8c8beb527253ea8f4d/nixos/modules/misc/label.nix) 
option in your `flake.nix` to pin the commit hash. For example:

```nix
{
  description = "My NixOS configuration";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      configuration = { allowUnfree = true; };
      nixosConfig = {
        system.nixos.label = "my-nixos-config";
      };
    };
  };
}
```

### Use `nixos-rebuild switch` instead of `nixos-rebuild boot`
When making changes to the system configuration, use `nixos-rebuild switch` instead of 
`nixos-rebuild boot`. This will apply the changes to the current generation, 
activate it, and make it the default boot option so any it can be tested and verified. 
`nixos-rebuild boot` will apply the changes but it will not activate until the 
next boot putting in you in a bad spot if you are not able to boot and don't have 
other generatios to rollback on.
More info in [nixos-rebuild](https://nixos.wiki/wiki/Nixos-rebuild).

### Clean up old Generations
Generations can take up a lot of disk space. It is a good idea to clean up old Generations
to free up disk space. This can be done using the `nix-collect-garbage` command. this
command will remove all the generations that are no longer needed. However, be careful 
when using this command as it can remove generations that are still needed. Use the 
`--delete-older` option to only remove generations that are older than a certain number 
of days.
Also, use [nix.gc](https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/misc/nix-gc.nix) options to run garbage collection automatically.
