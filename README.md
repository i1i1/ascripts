# Install

## macOS
``` sh
git clone https://github.com/9fans/plan9port/ && cd plan9port
./INSTALL
```

## Debian
``` sh
sudo apt-get install gcc libx11-dev libxt-dev libxext-dev libfontconfig1-dev
git clone https://github.com/9fans/plan9port && cd plan9port
./INSTALL
```

## Environment setup 

``` sh
export PLAN9="/path/to/plan9port"
export PATH="$PATH:$PLAN9/bin"
```

# My scripts

+ **A** - script which starts acme
+ **Clear** - script for clearing acme window
+ **Fm** - small file manager for acme
+ **Make** - utility which runs make for current project
+ **Man** - utility for viewing man inside acme
+ **Mdput** - live preview of MarkDown files via pandoc
+ **Slide[+-]?** - programms for doing text slides inside acme
+ **Tags** - programm for looking up for defenition in ctags generated files
+ **Tmp** - programm for opening scratch files
+ **winname** - programm for getting name of current acme window
+ **t[-+]** - simple programms for indentation
