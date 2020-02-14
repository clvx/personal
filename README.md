![](https://github.com/<OWNER>/<REPOSITORY>/workflows/<WORKFLOW_NAME>/badge.svg)

# Blog

Bitclvx blog

## Installation

    sudo snap install hugo
    
## Work locally

    git clone git@github.com:clvx/bitclvx-blog.git
    cd bitclvx-blog
    #Obtain theme
    git submodule init
    git submodule update
    hugo

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
