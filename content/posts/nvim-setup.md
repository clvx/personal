+++
author = "Luis Michael Ibarra"
title = "Nvim on Nix Setup"
date = "2024-10-03"
tags = [
    "nix",
    "nvim",
    "plugins",
]
+++

For a long time I've wanted to have a portable and reproducible editor configuration.

I've gone through several phases until I feel comfortable with [my dotfiles](https://github.com/clvx/nix-files/tree/master/config).
Even though my dotfiles include a little more than my nvim configuration, it takes 
most of it.

## .dotfile/

At first I used a `.dotfile` folder that I cloned and then symlink to the right places. 
It was a little painful to make updates as system dependencies and runtimes changed 
from my different devices. Also, the files weren´t tracked so I needed to track 
the changes in each system and then reconcile. Painful. I think I hit a straw 
when a rope version broke due my python version in 2 different systems.

## Git bare repo

This is a variation of the previous one based on [Attlassian's article](https://www.atlassian.com/git/tutorials/dotfiles) about it.
The only improvement with this method was tracking and avoiding symlinks as 
I tracked and ignored only things related to dotfiles in my home directory. So,
the challenge was only fixing and ensuring runtime was good. As a companion I 
used a mix of bash scripts and ansible to keep my system reproducible. I started 
looking for a better solution when work handed me a mac device.

## Nix - current

This is where the fun really begins. From the [NixOS website](https://nixos.org/guides/how-nix-works/):

> Nix is a purely functional package manager. This means that it treats packages 
> like values in purely functional programming languages - they are built by 
> functions that don’t have side-effects, and they never change after they have 
> been built. Nix stores packages in the Nix store, usually the directory /nix/store, 
> where each package has its own unique subdirectory such as /nix/store/b6gvzjyb2pg0kjfwrjmg1vfhh54ad73z-firefox-33.1/
> where b6gvzjyb2pg0… is a unique identifier for the package that captures all its 
> dependencies (it’s a cryptographic hash of the package’s build dependency graph). 
> This enables many powerful features.

As Nix has all the dependencies then all the runtimes issues dissapeared but this 
forced me to learn the Nix way and redo all my dotfiles.

Even though I use NixOS as my day to day, my dotfiles configuration is based on 
[home-manager](https://github.com/nix-community/home-manager) due the fact I use 
different operating sytems and/or linux distributions so I need something that can 
be portable. Hence, I have a flake which calls `config/nix/home.nix` under my user.
After that, everything else is regular nvim stuff.
There are some bits that are outside of config but it's just minimal and it depends 
on the use case.

```
    ~/nix-files/config
    ├── nix
    │   ├── common.nix
    │   ├── fzf.nix
    │   ├── git.nix
    │   ├── home.nix
    │   ├── nvim.nix
    │   ├── ssh.nix
    │   ├── tmux.nix
    │   └── zsh.nix
    ├── nvim
    │   ├── plugins
    │   │   ├── git-blame.lua
    │   │   ├── gitsigns.lua
    │   │   ├── go-nvim.lua
    │   │   ├── lualine-nvim.lua
    │   │   ├── noice-nvim.lua
    │   │   ├── nvim-cmp.lua
    │   │   ├── nvim-lspconfig.lua
    │   │   ├── nvim-tree.lua
    │   │   ├── nvim-treesitter.lua
    │   │   └── toggleterm.lua
    │   └── settings
    │       ├── basics.lua
    │       ├── basics.vim
    │       ├── keymaps.lua
    │       └── whichkey.lua
    └── tmux
        └── tmux.conf

6 directories, 23 files

```

* _home.nix_: It imports the rest of the modules. This is just a loader script.

* _common.nix_: It has all the common runtimes, LSPs and other utils for day to day. 
Think about `apt` or `yum`. The more I use nix the less useful I found installing 
runtimes as I started setting all my dependencies in each repository using nix 
and any program will have their dependencies installed at build time.

* _nvim.nix_: It's based on [home-manager's neovim module](https://github.com/nix-community/home-manager/blob/master/modules/programs/neovim.nix) to manage nvim. It enables it, installs defined plugins, generates an init.lua based 
on all the `extraConfig` configuration files and loads them.

The `extraConfig` variable supports vimscript and lua configuration. 

The `plugins` variable returns a list of all the plugins to be installed from 
`nixpkgs unstable`. This variable also allows building custom plugins generating a 
derivation of the plugin definition.
```
{ pkgs, pkgs-unstable, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    #package = pkgs-unstable.neovim;
    extraConfig = ''
      source  $HOME/nix-files/config/nvim/settings/basics.vim
      luafile $HOME/nix-files/config/nvim/settings/basics.lua
      luafile $HOME/nix-files/config/nvim/settings/whichkey.lua
      luafile $HOME/nix-files/config/nvim/settings/keymaps.lua
      luafile $HOME/nix-files/config/nvim/plugins/nvim-tree.lua
      luafile $HOME/nix-files/config/nvim/plugins/nvim-treesitter.lua
      luafile $HOME/nix-files/config/nvim/plugins/lualine-nvim.lua
      luafile $HOME/nix-files/config/nvim/plugins/nvim-lspconfig.lua
      luafile $HOME/nix-files/config/nvim/plugins/nvim-cmp.lua
      luafile $HOME/nix-files/config/nvim/plugins/toggleterm.lua
      luafile $HOME/nix-files/config/nvim/plugins/gitsigns.lua
      luafile $HOME/nix-files/config/nvim/plugins/go-nvim.lua
      luafile $HOME/nix-files/config/nvim/plugins/git-blame.lua
      luafile $HOME/nix-files/config/nvim/plugins/noice-nvim.lua
    '';

    plugins = with pkgs-unstable.vimPlugins; [
        vim-nix
        vim-cue

        #colorscheme
        gruvbox

        #identation lines
        indentLine

        #File tree
        nvim-web-devicons
        nvim-tree-lua

        ...
        
        #treesitter
        nvim-treesitter
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects
        nvim-treesitter-context
        #custom plugins
        (pkgs-unstable.vimUtils.buildVimPlugin {
          name = "guihua";
          src = pkgs.fetchFromGitHub {
            owner = "ray-x";
            repo = "guihua.lua";
            rev = "225db770e36aae6a1e9e3a65578095c8eb4038d3"; # or whatever branch you want to build
            hash = "sha256-V5rlORFlhgjAT0n+LcpMNdY+rEqQpur/KGTGH6uFxMY=";
          };
        })
    ];
  };

}
```

Each vim or lua file is your regular nvim file which means you can use regular lua 
and com the `vim.api` without issues.

## Caveats 

As Nix has a *read only filesystem*, it makes a little tricky to manage things that 
write to the store like treesitter grammars. You are suggested either to download the 
data needed into the store at build time like `nvim-treesitter.withAllGrammars` 
or to have runtime configuration OUTSIDE the nix store so you won´t get an error 
message of not being able to write to a read-only filesystem.
