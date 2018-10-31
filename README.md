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

+ **a** - script which starts acme
+ **aclear** - script for clearing acme window
+ **afm** - small file manager for acme
+ **amake** - utility which runs make for current project
+ **aman** - utility for viewing man inside acme
+ **amdput** - live preview of MarkDown files via pandoc
+ **aslide[+-]?** - programms for doing text slides inside acme
+ **atags** - programm for looking up for defenition in ctags generated files
+ **atmp** - programm for opening scratch files
+ **winname** - programm for getting name of current acme window
+ **t[-+]** - simple programms for indentation