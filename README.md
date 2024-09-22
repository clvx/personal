![](https://github.com/clvx/bitclvx-blog/workflows/CI/badge.svg)

# Personal website

## TODO

[ ] Add .direnv
[ ] Add shell.nix

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

- Github actions will build the site for any branch besides `gh-pages`. 

- It will only publish for `master`.

### Requirements
- uses: actions/checkout@v1
- uses: clvx/hugo-action@master
- uses: actions/upload-artifact@v1
- uses: actions/checkout@v2
- uses: actions/download-artifact@v1
- uses: webfactory/ssh-agent@v0.2.0
- uses: JamesIves/github-pages-deploy-action@releases/v3
