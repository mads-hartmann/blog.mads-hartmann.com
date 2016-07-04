#! /bin/sh

trap "emacsclient --server-file=$1 --eval '(kill-emacs)'; exit" SIGINT SIGHUP SIGKILL
tail -f /dev/null
