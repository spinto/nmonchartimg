Small bash script to render nmon charts generated via nmonchart as image

# Installation
Make sure you have the following software installed:
 - nmonchart (you can download the software from here: http://nmon.sourceforge.net/pmwiki.php?n=Site.Nmonchart, just uncompress it and place it into this script directory)
 - ksh and bash (if you do not have them, install them with your package manager (e.g. ```yum install -y bash ksh```))
 - nodejs, puppeteer and chrome (or any other headless browser you want to use in the backend). You can install these via:
 
 ```
 yum install -y nodejs
 yum install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
 npm install -g puppeteer-core
 ```

Then just copy the nmonchartimg.sh script into your system and give it execution rights:

```
curl -L 'https://github.com/spinto/nmonchartimg/raw/master/nmonchartimg.sh' > ./nmonchartimg.sh
chmod +x nmonchartimg.sh
```

# Usage:

```
Usage:
  nmonchartimg.sh [options] <chartID> <input> <output>

where <chartID> is the NMON CHART ID, which can be one of the following:

PHYSICAL_CPU    FSCACHE         READWRITE       CPU_USE         ADAPT_KBS       DISKREAD        JFS             CPU_UTIL        READWRITE       FSCACHE         NETPACKET       DISKBUSY        DISKBSIZE
POOLIDLE        MEMNEW          FORKEXEC        TOPDISK         ADAPT_TPS       DISKWRITE       IPC             CPU_USE         FORKEXEC        MEMNEW          NETSIZE         DISKREAD        DISKXFER
CPU_UTIL        RUNQ            FILEIO          NET             DISKBUSY        DISKWRITE       TOPDISK         RUNQ            FILEIO          PAGING          ADAPT_KBS       DISKREAD
REALMEM         PSWITCH         PAGING          NETPACKET       DISKBUSY        DISKBSIZE       PHYSICAL_CPU    PSWITCH         REALMEM         SWAPIN          ADAPT_TPS       DISKWRITE
VIRTMEM         SYSCALL         SWAPIN          NETSIZE         DISKREAD        DISKXFER        POOLIDLE        SYSCALL         VIRTMEM         NET             DISKBUSY        DISKWRITE

<input> is the input file, which can be:
  - an NMON file (.nmon)
  - an NMONCHART file (.html)
and <output> is the output .jpg or .png file

Options are:
 -h | --help                   Display this help
 -s | --size <width>x<height>  Set height and width of the graph (default is 800x400)
 -aT | --area-top <unit>       Set the chart area top margin to <unit>% (default is 10%)
 -aL | --area-left <unit>      Set the chart area left margin to <unit>% (default is 5%)
 -aW | --area-width <unit>     Set the chart area width to <unit>% (default is 80%)
 -aH | --area-height <unit>    Set the chart area height to <unit>% (default is 75%)
```
