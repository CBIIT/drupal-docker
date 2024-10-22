#!/bin/sh
# Start Apache in the background
httpd -D FOREGROUND &
wait
