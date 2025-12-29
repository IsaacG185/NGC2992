#!/bin/bash
export PATH=/man1/build_new/bin:$PATH
git pull -q origin master > git.log 2>&1
make all > make.log 2>&1
