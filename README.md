![](https://github.com/clvx/bitclvx-blog/workflows/CI/badge.svg)

# Personal website

## Version

    hugo            v0.126.1
    lukeorth/poison 07485e
    go              1.22.5

## Installation

    nix-shell -p hugo --run zsh
    hugo
    
## local development

    #cloning
    git clone git@github.com:clvx/personal.git
    cd personal

    #Obtain theme
    git submodule init
    git submodule update

    #run server
    hugo server

    #Upgrading theme
    git submodule fetch
    git submodule update --remote --merge

## CI

- Github actions will build the site. It uses the pre defined hugo template.
