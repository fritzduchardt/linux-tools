#!/usr/bin/env bash

XCLIP_COPY=(xclip -r -sel clip)
XCLIP_PASTE=(xclip -sel clip -o)
OUTPUT_FILTER=(grep -v "Creating new session:")
