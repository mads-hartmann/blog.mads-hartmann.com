---
layout: post
title: "Debugging host memory usage"
date: 2019-11-10 12:00:00
categories: SRE
colors: yellowblue
excerpt_separator: <!--more-->
---

At Glitch we run lots of projects on the same host. We've budgeted the memory usage quite tightly so depending on what the projects are doing, a machine might end up having very little free memory - which is good, we wouldn't want to waste resources. Lately, however, more and more of our machines started using almost all of their memory and some of them started using swap - which is bad. So I spend a day debugging memory usage patterns on our boxes. This is a little writeup of the tools I used and scripts I wrote during the investigation as I suspect I might need them again in the near future.

<!--more-->

## Tools 

Let's start off with the tools I used.

- `ps` - report a snapshot of the current processes.  
`ps` can tell you all sorts of things about the currently running processes. In our case we're only interested in the memory usage of the processes so we'll be using the following invocation:

  ```sh
  ps -eo uid,pid,ppid,rss,vsize,pmem,cmd -ww
  ```

  It's unpack that a bit:

  - `-e`: Tells ps to list all processes that are running rather than only 
  - `-o uid,pid,ppid,rss,vsize,pmem,cmd`: Specifies the output format. We're interested in the user id (uid), process id (pid), parent process id (ppid), the mount of physical memory used (Resident Set Size, rss), the total amount of memory used (Virtual memory SIZE, vsize).
  - `-ww`: Tells ps to use unlimited width when printing the output. That we we won't loose any information.

- `free` - Display amount of free and used memory in the system  
  `free -h` will list all number in human-readable format.

- awk. A cool text-processing programming language. I've previously written a [blog post about awk](https://blog.mads-hartmann.com/2018/09/29/enough-awk-to-get-by.html).

## Questions 

### What user is using the most memory

```sh
ps -eo uname,rss,vsize -ww \
| awk '
  NR > 1 { rssByUser[$1]+=$2 }
  END {
    for (i in rssByUser) {
      print i,rssByUser[i]/1024 "MB"
    }
  }
'
```

### What processes are using swap?

I couldn't figure out how to find this information with ps. I thought you would be able to subtract `rss` from `vsize` and get the swap usage, but I got weird results. Luckily I found a script by Milosz Galazka in his post ["How to display processes using swap space"](https://blog.sleeplessbeastie.eu/2016/12/26/how-to-display-processes-using-swap-space/) that I modified slightly.

Instead of using `ps` it reads information about the running processes from `/proc/<PID>/status`. The contents of the file is a bunch of lines using the format `KEY:\tVALUE` such as `VmSwap:	128 kB` and `Name:	nginx`.

Here's my modified version of the program:

```sh
export AWK_PROGRAM='
{
  process[$1]=$2
  sub(/^[ \t]+/,"",process[$1]) # strip whitespace
  sub(" kB","",process[$1])     # remove kB unit
}
END {
  split(process["Uid"], uids, " ")
  if (process["VmSwap"] && process["VmSwap"] != "0") {
    print process["VmSwap"]/1024,process["Name"],uids[1]
  }
}
'
find /proc \
  -maxdepth 2 \
  -path "/proc/[0-9]*/status" \
  -readable \
  -exec awk -v FS=":" "$AWK_PROGRAM" '{}' \; 2> /dev/null \
| sort -n
```

By setting the field separator (`FS`) to `:` it build up information about the process into the `process` associative array for each line in the file, and when the file has been processed - marked by the `END` rule - it prints out the information we're interested in.

### What user is using the most SWAP

```sh
export AWK_PROGRAM='
{
  process[$1]=$2
  sub(/^[ \t]+/,"",process[$1]) # strip whitespace
  sub(" kB","",process[$1])     # remove kB unit
}
END {
  split(process["Uid"], uids, " ") # we only want the first user.
  if (process["VmSwap"] && process["VmSwap"] != "0") {
    print process["VmSwap"],uids[1]
  }
}
'
find /proc \
  -maxdepth 2 \
  -path "/proc/[0-9]*/status" \
  -readable \
  -exec awk -v FS=":" "$AWK_PROGRAM" '{}' \; 2> /dev/null \
| awk '
  { users[$2]=+$1 }
  END { 
    for (i in users) {
      print users[i]/1024 "MB",i
    }
   }
' \
| sort -n
```

### How is user X spending RAM

```sh
# Fields:
# $1 = USER
# $6 = RSS (memory usage)
# $11 = COMMAND
# $12 - XYZ = ARGUMENT TO THE COMMAND
# 
# This sums and groups the memory usage for all processes owned by user UID
# They're grouped by the command and the first argument to the command. Otherwise a lot would show up a `node`.
#
ps aux  \
| awk '$1 == UID {arr[$11" "$12]+=$6/1024}; END {for (i in arr) {print arr[i] "MB",i}}' \
| sort -n
```

## Other resources

 -[This post](https://www.freshblurbs.com/blog/2007/01/25/how-profile-memory-linux.html)
