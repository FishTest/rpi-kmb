# rpi-kmb
Raspberry PI Kernel &amp; Modules builder

          ┌───────┤ Raspberry PI Kernel Building Tools V0.01 ├───────┐
          │ Functin List:                                            │
          │                                                          │
          │               1 Kernel Source                            │
          │               2 Kernel Building                          │
          │               3 External Modules Building                │
          │               4 PI Modules                               │
          │                                                          │
          │                                                          │
          │              <Ok>                  <Exit>                │
          │                                                          │
          └──────────────────────────────────────────────────────────┘

]1 Kernel Source

          ┌───────┤ Raspberry PI Kernel Building Tools V0.01 ├───────┐
          │ Source code config:                                      │
          │                                                          │
          │                      1 Downlad                           │
          │                      2 Update                            │
          │                      3 Version                           │
          │                      4 Clean Source                      │
          │                      5 Clean Target                      │
          │                                                          │
          │                                                          │
          │              <Ok>                  <Return>              │
          │                                                          │
          └──────────────────────────────────────────────────────────┘

1 Download:Download kernel source from github(https://github.com/raspberrypi/linux)
Full clone
git clone https://github.com/raspberrypi/linux
2 Update
pull newest source from github
3 Version

          ┌───────┤ Raspberry PI Kernel Building Tools V0.01 ├───────┐
          │ Choose an option.                                        │
          │                                                          │
          │               1 By Tag                                   │
          │               2 By Hash                                  │
          │               3 Sync code to building DIR                │
          │                                                          │
          │                                                          │
          │              <Ok>                  <Return>              │
          │                                                          │
          └──────────────────────────────────────────────────────────┘
  1 By Tag: checkout source by github tag
  2 By Hash: checkout source by github hash
  3 Sync code to building DIR: sync code from downloaded source to building dir by selected pi modules
4 Clean Source: remove source dir
5 Clean Target: remove building dir

]2 Kernel Building

          ┌───────┤ Raspberry PI Kernel Building Tools V0.01 ├───────┐
          │ Functin List:                                            │
          │                                                          │
          │                  1 Apply kernel config                   │
          │                  2 Build modules                         │
          │                  3 Build Image                           │
          │                  4 Build dtbs                            │
          │                  5 Build all                             │
          │                  6 Modules prepare                       │
          │                                                          │
          │                                                          │
          │              <Ok>                  <Return>              │
          │                                                          │
          └──────────────────────────────────────────────────────────┘

1 Apply kernel config by modules
for example:
make bcmrpi_defconfig
make bcm2709_defconfig
make bcm2711_defconfig
on 64bit host
make ARCH=arm64 bcm2711_defconfig

2 Bulid modules
make modules

3 Build Image
make zImage

4 Build dtbs
make dtbs

5 Build all
make zImage modules dtbs

6 Modules prepare
make modules_prepare

]3 External Modules Building

          ┌───────┤ Raspberry PI Kernel Building Tools V0.01 ├───────┐
          │ Function List:                                           │
          │                                                          │
          │                         1 Select                         │
          │                         2 Build                          │
          │                         3 Packet                         │
          │                                                          │
          │                                                          │
          │              <Ok>                  <Return>              │
          │                                                          │
          └──────────────────────────────────────────────────────────┘

1 Select modules in extmodules dir
2 Build selected modules
3 packet modules

]4 PI Modules 

          ┌───────┤ Raspberry PI Kernel Building Tools V0.01 ├───────┐
          │ Raspberry PI Modules:                                    │
          │                                                          │
          │    [*] 1  PI 1,CM 1 (bcmrpi_defconfig)                   │
          │    [*] 2  PI 2,3,CM 3 (bcm2709_defconfig)                │
          │    [*] 3  PI 4,CM 4 (bcm2711_defconfig)                  │
          │    [ ] 4  PI 3,CM 3 64bit (bcmrpi3_defconfig)            │
          │    [*] 5  PI 4,CM 4 64bit (bcm2711_defconfig_64bit)      │
          │                                                          │
          │                                                          │
          │              <Ok>                  <Return>              │
          │                                                          │
          └──────────────────────────────────────────────────────────┘

select PI modules used to build kernel and modules

Example:
find current kernel version:
pi@raspberrypi:~/rpi-kmb $ dpkg -l raspberrypi-kernel
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name               Version      Architecture Description
+++-==================-============-============-===============================
ii  raspberrypi-kernel 1.20210303-1 armhf        Raspberry Pi bootloader


1: Build kernel
A. Select PI Modules
B. Kernel Source -> Download
C. Kernel Source -> Version -> by TAG -> Select 1.20210303-1 -> Sync code to target dir
D. Kernel Build -> Apply kernel config
E. Kernel Build -> Build all

2: Build modules
put your modules source into rpi-kmb/extmodules dir
set K_SRC para in module's Makefile (make command)
A. Select PI Modules
B. Kernel Source -> Download
C. Kernel Source -> Version -> by TAG -> Select 1.20210303-1 -> Sync code to target dir
D. Kernel Build -> Apply kernel config
E. Kernel Build -> Build modules
F. External Modules Building -> Select modules in extmodules dir -> Build
G. got modules in output dir



