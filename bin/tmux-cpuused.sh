#!/bin/bash

grep 'cpu' /proc/stat | head -n 1 | awk '{usage=($2+$4)*100/($2+$4+$5); printf "%.2f", usage}'
