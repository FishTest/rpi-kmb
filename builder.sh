#!/bin/bash

VERSION="0.01"

BUILDER_DIR=$(pwd)"/"
SOURCE_DIR=$BUILDER_DIR"linux/"
KERNEL_SRC_GITHUB="https://github.com/raspberrypi/linux"

MENU_TITLE="Raspberry PI Kernel Building Tools V"$VERSION
MENU_BG_TITLE="Raspberry PI Kernel Building Tools"

TAG_CURRENT=""
OBJECTS_CURRENT=""
BUILD_PI1="ON"
BUILD_PI2="ON"
BUILD_PI4="ON"
BUILD_PI3="OFF"
BUILD_PI4_64="ON"

OUTPUT_PREFIX="aoide_dac_"

HASH_DEFAULT="6af8ae321a801a4e20183454c65eb0d23069d8ac"
HASH_CURRENT=""

ARR_SRC=(bcmrpi_defconfig bcm2709_defconfig bcm2711_defconfig bcmrpi3_defconfig bcm2711_defconfig_64bit)

SYS_REQ_ARM="git bc bison flex libssl-dev make"
SYS_REQ_I386="$SYS_REQ_ARM libc6-dev libncurses5-dev crossbuild-essential-armhf"
SYS_REQ_X86_64="$SYS_REQ_I386 crossbuild-essential-arm64"

KERNEL_SRC=$BUILDER_DIR"linux/"
EXT_MODULES_DIR=$BUILDER_DIR"extmodules/"
CROSS_TOOL_X86=
CROSS_TOOL_X86_64=
CROSS_TOOL_ARM64=

CROSS_TOOLS_OPT="ARCH=arm CROSS_COMPILE="$CROSS_TOOLS_PATH"arm-linux-gnueabihf-"
CROSS_TOOLS_64BIT_OPT="ARCH=arm64 CROSS_COMPILE=/opt/aarch64/bin/aarch64-linux-gnu-"

#Builde machine arch
M_ARCH=""
VERSION_DIR=""
BOARDNAME=""

# Init --------------------------------------------------
# Get builder machine arch
function check_arch(){
    A=$(arch)
    if [[ $A == *"arm"* ]]; then
        M_ARCH="arm"
    fi
	if [[ $A == *"i386"* ]]; then
		M_ARCH="i386"
	fi
    if [[ $A == *"x86_64"* ]]; then
		M_ARCH="x86_64"
	fi
}

# Get CPU core count
function check_cpu_num(){
    CPU_NUM=$(lscpu | grep "^CPU(s):" | tr -cd "[0-9]")
}

# Auto check and install prerequisite packages
function check_system_required(){
    #on arm
    if [ "$M_ARCH" = "arm" ]; then
        PACKAGES=$SYS_REQ_ARM
    fi
     
    #on i386
    if [ "$M_ARCH" = "i386" ]; then
        PACKAGES=$SYS_REQ_I386
    fi
        
    #on X86_64
    if [ "$M_ARCH" = "X86_64" ]; then
        PACKAGES=$SYS_REQ_X86_64
    fi
    
    REQ_STATE=$(dpkg -l $PACKAGES | grep "un  ")
    if [ -n "$REQ_STATE" ]; then
        sudo apt update
        sudo apt -y install $PACKAGES
    fi
}

# get exists tag
function get_exists_tag(){
    if [ -f $BUILDER_DIR"TAG" ]; then
        TAG_CURRENT=$(cat $BUILDER_DIR"TAG")
    fi
}

function check_exists_hash(){
    if [ -f $BUILDER_DIR"HASH" ]; then
        HASH_CURRENT=$(cat $BUILDER_DIR"HASH")
    else
        HASH_CURRENT=$HASH_DEFAULT
    fi
}

function get_boardname(){
    case $1 in
            '"1"')
            BOARDNAME="Raspberry PI 1, Zero, Zero W, CM 1"
            ;;
            '"2"')#
            BOARDNAME="Raspberry PI 2, 3, 3+, CM 3"
            ;;
            '"3"')
            BOARDNAME="Raspberry PI 4"
            ;;
            '"4"')
            BOARDNAME="Raspberry PI 3 64bit"
            ;;
            '"5"')
            BOARDNAME="Raspberry PI 4 64bit"
            ;;
    esac
}

# source --------------------------------------------------
# Source download
function source_download(){
    if [ ! -d $SOURCE_DIR ]; then
        git clone $KERNEL_SRC_GITHUB linux
    fi
}

# Source update
function source_update(){
    if [ ! -d $SOURCE_DIR ]; then
        source_download
    else
        cd $SOURCE_DIR
        git pull
        cd $BUILDER_DIR
    fi
}

# checkout source by tag
function menu_source_tag(){
    cd $SOURCE_DIR
    #taglist=$(git tag -l --sort=-creatordate)
    tag_array=()
    new_tag_array=()
    IFS=$'\n' read -r -d '' -a tag_array < <( git tag -l --sort=-creatordate && printf '\0' )
    cd $BUILDER_DIR
    for value in "${tag_array[@]}"
    do
        new_tag_array+=($value)
        new_tag_array+=('"'$value'"')
    done
    unset tag_array
    #echo "${new_tag_array[*]}"

    selected_tag=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --menu "Choose a tag from list:" \
        0 0 0 "${new_tag_array[@]}"  \
        3>&1 1>&2 2>&3)
    if [ $selected_tag ]; then
        echo $selected_tag>$BUILDER_DIR"TAG"
        TAG_CURRENT=$selected_tag
        cd $BUILDER_DIR"linux/"
        git checkout $TAG_CURRENT
        cd $BUILDER_DIR
        menu_source_sync
    fi
    unset new_tag_array
}

# checkout source by tag
function menu_source_hash(){
    HASH_CURRENT=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --inputbox "What is your pet's name?" \
        0 60 "$HASH_CURRENT" \
        3>&1 1>&2 2>&3)
    echo $HASH_CURRENT > $BUILDER_DIR"HASH"
}

# Sync source code to build dir
function source_sync(){
    echo $OBJECTS_CURRENT
    if [ -d $BUILDER_DIR"target" ]; then
        rm -rf $BUILDER_DIR"target"
    fi
    mkdir $BUILDER_DIR"target"
    
    if [[ $OBJECTS_CURRENT == *"1"* ]]; then
        echo "Sync code for PI 1"
        rsync -avqp --exclude .git linux $BUILDER_DIR"/target/bcmrpi_defconfig"
        echo "+" > $BUILDER_DIR"/target/bcmrpi_defconfig/linux/.scmversion"
        echo "Sync complete."
    fi
    if [[ $OBJECTS_CURRENT == *"2"* ]]; then
        echo "Sync code for PI 2,3"
        rsync -avqp --exclude .git linux $BUILDER_DIR"/target/bcm2709_defconfig"
        echo "+" > $BUILDER_DIR"/target/bcm2709_defconfig/linux/.scmversion"
        echo "Sync complete."
    fi
    if [[ $OBJECTS_CURRENT == *"3"* ]]; then
        echo "Sync code for PI 4"
        rsync -avqp --exclude .git linux $BUILDER_DIR"/target/bcm2711_defconfig"
        echo "+" > $BUILDER_DIR"/target/bcm2711_defconfig/linux/.scmversion"
        echo "Sync complete."
    fi
    if [[ $OBJECTS_CURRENT == *"4"* ]]; then
        echo "Sync code for PI 3 64bit"
        rsync -avqp --exclude .git linux $BUILDER_DIR"/target/bcmrpi3_defconfig"
        echo "+" > $BUILDER_DIR"/target/bcmrpi3_defconfig/linux/.scmversion"
        echo "Sync complete."
    fi
    if [[ $OBJECTS_CURRENT == *"5"* ]]; then
        echo "Sync code for PI 4 64bit"
        rsync -avqp --exclude .git linux $BUILDER_DIR"/target/bcm2711_defconfig_64bit"
        echo "+" > $BUILDER_DIR"/target/bcm2711_defconfig_64bit/linux/.scmversion"
        echo "Sync complete."
    fi
}
        
# Sync code to build dir
function menu_source_sync(){
    if (whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --yesno "Sync source code to build dir?" \
        0 60 0 \
        3>&1 1>&2 2>&3) then
        source_sync
    fi
}


function generate_kernel_sources(){
    if [ ! -f $KERNEL_SRC ]; then
        git clone $KERNEL_SRC_GITHUB linux
    else
        result=$(git show $HASH_SRC | grep bad)
        # if [ ! empty ]; then
            # cd $KERNEL_SRC
            # git pull
        # else
            # echo "failed:cannt found the speficed hash."
            # exit
        # fi
        
        # echo "check hash in source"
    fi
    if [ ! -f $BUILDER_DIR"linux_by_hash/"$HASH_SRC ]; then
        mkdir $BUILDER_DIR"linux_by_hash/"$HASH_SRC
    fi
    
    create_multi_sources
}

function build_modules_prepare(){
    if X86_64 ; then 
        echo "modules_prepare under"
        for i in "${ARR_SRC[@]}"
        do
            echo "Copying kernel source for [ $i ] ..."
            # cd linux_by_hash/$HASH_SRC/linux linux_by_hash/$HASH_SRC/$i
            # if bcm2709_defconfig
                # make bcm2709_defconfig
            # fi
            # if 32bit
            # make ARCH=$ARCH CROSS_COMPILE=arm-linux-gnueabihf- modules_prepare
            # if 64bit 
            # make ARCH=$ARCH CROSS_COMPILE=aarch64-linux-gnu- modules_prepare
        done
    fi
}
# Menu source
function menu_source(){
	OPTION_SOURCE=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --menu "Source code config:" \
        --cancel-button "Return" 0 60 0 \
        "1" "Downlad" \
        "2" "Update" \
        "3" "Version" \
        "4" "Clean Source" \
        "5" "Clean Target" \
        3>&1 1>&2 2>&3)
    if [ $OPTION_SOURCE ]; then
        case $OPTION_SOURCE in
            "1")
            source_download
            ;;
            "2")
            source_update
            ;;
            "3")
            menu_source_version
            ;;
            "4")
            if (whiptail --title "$MENU_TITLE" \
                --backtitle "$MENU_BG_TITLE" \
                --yesno "Are you sure to clear source?" \
                0 60 0 \
                3>&1 1>&2 2>&3) then
                rm -rf $BUILDER_DIR"linux"
            fi
            ;;
            "5")
            if (whiptail --title "$MENU_TITLE" \
                --backtitle "$MENU_BG_TITLE" \
                --yesno "Are you sure to clear target?" \
                0 60 0 \
                3>&1 1>&2 2>&3) then
                rm -rf $BUILDER_DIR"target"
            fi
            ;;
        esac
        menu_source
    else
        menu_main
    fi
}

# Menu source
function menu_source_version(){
	OPTION_SOURCE=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --menu "Choose an option." \
        --cancel-button "Return" 0 60 0 \
        "1" "By Tag" \
        "2" "By Hash" \
        "3" "Sync code to building DIR" \
        3>&1 1>&2 2>&3)
    if [ $OPTION_SOURCE ]; then
        case $OPTION_SOURCE in
            "1")
            menu_source_tag
            ;;
            "2")
            menu_source_hash
            cd $BUILDER_DIR"linux/"
            git checkout $HASH_CURRENT
            cd $BUILDER_DIR
            menu_source_sync
            ;;
            "3")
            menu_source_sync
            ;;
        esac
        menu_source
    else
        menu_source
    fi
}

function kernel_action(){
    if [[ $OBJECTS_CURRENT == *"1"* ]]; then
        echo "PI 1"
        cd $BUILDER_DIR"/target/bcmrpi_defconfig/linux"
        if [[ $M_ARCH == *"arm"* ]]; then
            make $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        else
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        fi
    fi
    if [[ $OBJECTS_CURRENT == *"2"* ]]; then
        echo "PI 2,3"
        cd $BUILDER_DIR"/target/bcm2709_defconfig/linux"
        if [[ $M_ARCH == *"arm"* ]]; then
            make $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        else
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        fi
    fi
    if [[ $OBJECTS_CURRENT == *"3"* ]]; then
        echo "PI 4"
        cd $BUILDER_DIR"/target/bcm2711_defconfig/linux"
        if [[ $M_ARCH == *"arm"* ]]; then
            make $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        else
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        fi
    fi
    if [[ $M_ARCH == *"x86_64"* ]]; then
        if [[ $OBJECTS_CURRENT == *"4"* ]]; then
            echo "PI 3 64bit"
            cd $BUILDER_DIR"/target/bcmrpi3_defconfig/linux"
            make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- $KERNEL_BUILD_OPTION_64BIT "-j"$CPU_NUM
        fi
        if [[ $OBJECTS_CURRENT == *"5"* ]]; then
            echo "PI 4 64bit"
            cd $BUILDER_DIR"/target/bcm2711_defconfig_64bit/linux"
            make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- $KERNEL_BUILD_OPTION_64BIT "-j"$CPU_NUM
        fi
    else
        echo "Error:Cannot build 64bit kernel on 32bit machine."
    fi
    cd $BUILDER_DIR
    KERNEL_BUILD_OPTION=""
    KERNEL_BUILD_OPTION_64BIT=""
}

function kernel_action_config(){
    if [[ "$CURRENT_KERNEL" == "1" ]]; then
        echo "PI 1"
        cd $BUILDER_DIR"/target/bcmrpi_defconfig/linux"
        if [[ $M_ARCH == *"arm"* ]]; then
            make $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        else
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        fi
    fi
    if [[ "$CURRENT_KERNEL" == "2" ]]; then
        echo "PI 2,3"
        cd $BUILDER_DIR"/target/bcm2709_defconfig/linux"
        if [[ $M_ARCH == *"arm"* ]]; then
            make $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        else
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        fi
    fi
    if [[ "$CURRENT_KERNEL" == "3" ]]; then
        echo "PI 4"
        cd $BUILDER_DIR"/target/bcm2711_defconfig/linux"
        if [[ $M_ARCH == *"arm"* ]]; then
            make $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        else
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_BUILD_OPTION "-j"$CPU_NUM
        fi
    fi
    if [[ $M_ARCH == *"x86_64"* ]]; then
        if [[ "$CURRENT_KERNEL" == "4" ]]; then
            echo "PI 3 64bit"
            cd $BUILDER_DIR"/target/bcmrpi3_defconfig/linux"
            make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- $KERNEL_BUILD_OPTION_64BIT "-j"$CPU_NUM
        fi
        if [[ "$CURRENT_KERNEL" == "5" ]]; then
            echo "PI 4 64bit"
            cd $BUILDER_DIR"/target/bcm2711_defconfig_64bit/linux"
            make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- $KERNEL_BUILD_OPTION_64BIT "-j"$CPU_NUM
        fi
    else
        echo "Error:Cannot build 64bit kernel on 32bit machine."
    fi
    cd $BUILDER_DIR
    KERNEL_BUILD_OPTION=""
    KERNEL_BUILD_OPTION_64BIT=""
}


function kernel_config_apply(){
    if [[ $OBJECTS_CURRENT == *"1"* ]]; then
        CURRENT_KERNEL="1"
        KERNEL_BUILD_OPTION="bcmrpi_defconfig"
        kernel_action_config
    fi
    if [[ $OBJECTS_CURRENT == *"2"* ]]; then
        CURRENT_KERNEL="2"
        KERNEL_BUILD_OPTION="bcm2709_defconfig"
        kernel_action_config
    fi
    if [[ $OBJECTS_CURRENT == *"3"* ]]; then
        CURRENT_KERNEL="3"
        KERNEL_BUILD_OPTION="bcm2711_defconfig"
        kernel_action_config
    fi
    if [[ $M_ARCH == *"x86_64"* ]]; then
        if [[ $OBJECTS_CURRENT == *"4"* ]]; then
            CURRENT_KERNEL="4"
            KERNEL_BUILD_OPTION_64BIT="bcmrpi3_defconfig"
            kernel_action_config
        fi
        if [[ $OBJECTS_CURRENT == *"5"* ]]; then
            CURRENT_KERNEL="5"
            KERNEL_BUILD_OPTION_64BIT="bcm2711_defconfig"
            kernel_action_config
        fi
    else
        echo "Error:Cannot build 64bit kernel on 32bit machine."
    fi
    cd $BUILDER_DIR
}

function kernel_image(){
    KERNEL_BUILD_OPTION="zImage"
    KERNEL_BUILD_OPTION_64BIT="Image"
    kernel_action
}

function kernel_modules(){
    KERNEL_BUILD_OPTION="modules"
    KERNEL_BUILD_OPTION_64BIT=$KERNEL_BUILD_OPTION
    kernel_action
}

function kernel_dtbs(){
    KERNEL_BUILD_OPTION="dtbs"
    KERNEL_BUILD_OPTION_64BIT=$KERNEL_BUILD_OPTION
    kernel_action
}

function kernel_all(){
    KERNEL_BUILD_OPTION="zImage modules dtbs"
    KERNEL_BUILD_OPTION_64BIT="Image modules dtbs"
    kernel_action
}

function kernel_modules_prepare(){
    echo $OBJECTS_CURRENT
    KERNEL_BUILD_OPTION="modules_prepare"
    KERNEL_BUILD_OPTION_64BIT=$KERNEL_BUILD_OPTION
    kernel_action
}

# Menu kernel
function menu_kernel() {
    KERNEL_OPTION=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --menu "Functin List:" \
        --cancel-button "Return" \
        0 60 0 \
        "1" "Apply kernel config" \
        "2" "Build modules" \
        "3" "Build Image" \
        "4" "Build dtbs" \
        "5" "Build all" \
        "6" "Modules prepare" \
        3>&1 1>&2 2>&3)
    
    if [ $KERNEL_OPTION ]; then
        case $KERNEL_OPTION in
            "1")
            kernel_config_apply
            ;;
            "2")#
            kernel_modules
            ;;
            "3")
            kernel_image
            ;;
            "4")
            kernel_dtbs
            ;;
            "5")
            kernel_all
            ;;
            "6")
            kernel_modules_prepare
            ;;
        esac
        menu_kernel
    else
        menu_main
    fi
}

function check_exists_extmodules(){
    if [ -f $BUILDER_DIR"MODULES" ]; then
        EXTMODULES_CURRENT=$(cat $BUILDER_DIR"MODULES")
    else
        EXTMODULES_CURRENT=""
    fi
}

#list folders
function menu_ext_select(){
    ARR_EXTMODULES=()
    ARR_EXTMODULES_NEW=()
    ARR_EXTMODULES=($(ls $EXT_MODULES_DIR))
#    echo $MODULES
    # cd $BUILDER_DIR
    check_exists_extmodules
    for value in "${ARR_EXTMODULES[@]}"
    do
        #echo $value
        ARR_EXTMODULES_NEW+=($value)
        ARR_EXTMODULES_NEW+=($value)
        if [[ $EXTMODULES_CURRENT =~ '"'$value'"' ]]; then
            ARR_EXTMODULES_NEW+=("ON")
        else
            ARR_EXTMODULES_NEW+=("OFF")
        fi
    done
   
    unset ARR_EXTMODULES
    #echo "${ARR_MODULES_NEW[*]}"

    selected_extmodules=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --checklist "Choose modules from list:" \
        0 0 0 "${ARR_EXTMODULES_NEW[@]}"  \
        3>&1 1>&2 2>&3)
    echo $selected_extmodules>$BUILDER_DIR"MODULES"
    unset ARR_EXTMODULES_NEW
}

function get_version_dir(){
    #try to get linux version from first dir in target
    if [ -d $BUILDER_DIR"target/" ]; then
        VERSION_DIR=$(ls $BUILDER_DIR"target/" | head -n1)
        if [ ! -z $VERSION_DIR ]; then
            VERSION_DIR=$BUILDER_DIR"target/"$VERSION_DIR"/linux/"
            return
        fi
    fi
    if [ -d $BUILDER_DIR"linux/" ]; then
        VERSION_DIR=$BUILDER_DIR
    fi
    #try to get linux version from origin linux dir
}

function check_current_module_version(){
    get_version_dir
    VERSION_FILE=$VERSION_DIR"Makefile"
    if [ -f $VERSION_FILE ]; then
        VERSION_MAIN=$(cat $VERSION_FILE | grep ^VERSION | tr -cd "[0-9]")
        PATCHLEVEL=$(cat $VERSION_FILE | grep ^PATCHLEVEL | tr -cd "[0-9]")
        SUBLEVEL=$(cat $VERSION_FILE | grep ^SUBLEVEL | tr -cd "[0-9]")
        VERSION_FULL=$VERSION_MAIN"."$PATCHLEVEL"."$SUBLEVEL
    fi
}

# Build ext modules
# OBJECTS Raspberry PI MODULES
# MODULE selected ext modules
function ext_modules_build(){
    # 遍历所有的外部模块文件夹，然后根据当前平台进行构建
    # Build extmodules for PI 1
    echo $1
    echo $M_ARCH
    case $1 in
        '"1"')
        MODULE_KERNEL_SRC=$BUILDER_DIR"target/bcmrpi_defconfig/linux/"
        case $M_ARCH in
            "arm")
            make KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
            "i386" | "x86_64")
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM 
            ;;
        esac
        ;;
        '"2"')
        MODULE_KERNEL_SRC=$BUILDER_DIR"target/bcm2709_defconfig/linux/"
        case $M_ARCH in
            "arm")
            make KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
            "i386" | "x86_64")
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
        esac
        ;;
        '"3"')
        MODULE_KERNEL_SRC=$BUILDER_DIR"target/bcm2711_defconfig/linux/"
        case $M_ARCH in
            "arm")
            make KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
            "i386" | "x86_64")
            make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
        esac
        ;;
        '"4"')
        MODULE_KERNEL_SRC=$BUILDER_DIR"target/bcmrpi3_defconfig/linux/"
        case $M_ARCH in
            "x86_64")
            make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
        esac
        ;;
        '"5"')
        MODULE_KERNEL_SRC=$BUILDER_DIR"target/bcm2711_defconfig_64bit/linux/"
        case $M_ARCH in
            "x86_64")
            make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KERNEL_SRC=$MODULE_KERNEL_SRC -j$CPU_NUM
            ;;
        esac
        ;;
    esac
    HAS_KO=$(ls *.ko)
    if [ ! -z "$HAS_KO" ]; then
        chmod +x *.ko
    fi
}

function ext_modules_copy(){
    check_current_module_version
    if [ -z "$VERSION_FULL" ]; then
        return
    fi

    case $1 in
        '"1"')
        OUTPUT_DIR=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"+/kernel/"
        OUTPUT_DIR_CODECS=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"+/kernel/sound/soc/codecs/"
        OUTPUT_DIR_BCM=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"+/kernel/sound/soc/bcm/"
        ;;
        '"2"')
        OUTPUT_DIR=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v7+/kernel/"
        OUTPUT_DIR_CODECS=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v7+/kernel/sound/soc/codecs/"
        OUTPUT_DIR_BCM=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v7+/kernel/sound/soc/bcm/"
        ;;
        '"3"')
        OUTPUT_DIR=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v7l+/kernel/"
        OUTPUT_DIR_CODECS=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v7l+/kernel/sound/soc/codecs/"
        OUTPUT_DIR_BCM=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v7l+/kernel/sound/soc/bcm/"
        ;;
        '"4"')
        OUTPUT_DIR=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v8-rpi3+/kernel/"
        OUTPUT_DIR_CODECS=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v8-rpi3+/kernel/sound/soc/codecs/"
        OUTPUT_DIR_BCM=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v8-rpi3+/kernel/sound/soc/bcm/"
        ;;
        '"5"')
        OUTPUT_DIR=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v8+/kernel/"
        OUTPUT_DIR_CODECS=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v8+/kernel/sound/soc/codecs/"
        OUTPUT_DIR_BCM=$BUILDER_DIR"output/lib/modules/"$VERSION_FULL"-v8+/kernel/sound/soc/bcm/"
        ;;
    esac
    
    echo "make output dir"
    echo $OUTPUT_DIR_CODECS
    mkdir -p $OUTPUT_DIR_CODECS
    echo $OUTPUT_DIR_BCM
    mkdir -p $OUTPUT_DIR_BCM
    echo $BUILDER_DIR"output/boot/overlays"
    mkdir -p $BUILDER_DIR"output/boot/overlays"
    echo $2
    
    if [[ $2 == *"aoide"* ]]; then
        BCM_MODULE=$(ls *.ko | grep aoide)
        if [ ! -z "$BCM_MODULE" ]; then
            cp $BCM_MODULE $OUTPUT_DIR_BCM
        fi
        CODECS_MODULE=$(ls *.ko | grep -v aoide)
        if [ ! -z "$CODECS_MODULE" ]; then
            cp $CODECS_MODULE $OUTPUT_DIR_CODECS
        fi
    elif [[ $2 == *"raspivoicehat"* ]]; then
        BCM_MODULE=$(ls snd-soc-wm8960-soundcard.ko)
        if [ ! -z "$BCM_MODULE" ]; then
            cp snd-soc-wm8960-soundcard.ko $OUTPUT_DIR_BCM
        fi
        CODECS_MODULE=$(ls snd-soc-wm8960.ko)
        if [ ! -z "$CODECS_MODULE" ]; then
            cp snd-soc-wm8960.ko $OUTPUT_DIR_CODECS
        fi
    else
        NORMAL_MODULE=$(ls *.ko)
        if [ ! -z "$NORMAL_MODULE" ]; then
            cp $NORMAL_MODULE $OUTPUT_DIR
        fi
    fi
    HAS_DTBO=$(ls *.dtbo)
    if [ ! -z "$HAS_DTBO" ]; then
        cp *.dtbo $BUILDER_DIR"output/boot/overlays" 
    fi
}

function ext_modules_targz(){
    if [ -d $BUILDER_DIR"output" ]; then
        cd $BUILDER_DIR"output"
        tar zcvf $OUTPUT_PREFIX$VERSION_FULL".tar.gz" lib/ boot/
    fi
    cd $BUILDER_DIR
}

# build modules
function menu_ext_build(){
    # read selected modules from config file
    check_current_module_version
    check_exists_extmodules
    check_exists_objects
    if [ -z "$OBJECTS_CURRENT" ]; then
        whiptail --title "$MENU_TITLE" --backtitle "$MENU_BG_TITLE" --msgbox "Please select some PI modules in PI Modules. Choose Ok to continue." 0 60
        return
    fi 
    
    if [ -z "$EXTMODULES_CURRENT" ]; then
        whiptail --title "$MENU_TITLE" --backtitle "$MENU_BG_TITLE" --msgbox "Please select some MODULES in Ext Modules Building. Choose Ok to continue." 0 60
        return
    fi
    echo "Clean output directory"
    rm -rf $BUILDER_DIR"output"
    echo "Start building extmodules"
    IFS_EM=' ' read -r -a ARR_EXTMODULES_CURRENT <<< "$EXTMODULES_CURRENT"
    #ARR_EXTMODULES_CURRENT=($EXTMODULES_CURRENT)
    # 在已经选择的驱动中进行遍历驱动型号中遍历
    
    # 读取已经选择的树莓派型号
    IFS_O=' ' read -r -a ARR_OBJECTS_CURRENT <<< "$OBJECTS_CURRENT"
    
    echo " ] Kernel Version: $VERSION_FULL [ "
    for value_o in "${ARR_OBJECTS_CURRENT[@]}"
    do
        # 获取树莓派型号
        get_boardname $value_o
        echo "-------------------------------------------------"
        echo "[ Build for $BOARDNAME ]"
        for value_em in "${ARR_EXTMODULES_CURRENT[@]}"
        do
            # 树莓派 型号
            echo " > Module: $value_em"
            # 进入相应的源代码文件夹
            cd $EXT_MODULES_DIR${value_em//'"'}
            # Build
            # 开始构建此型号的树莓派对应的驱动
            ext_modules_build $value_o
            # 把驱动复制到输出文件夹
            ext_modules_copy $value_o $value_em
            
        done
        echo "-------------------------------------------------"
    done
    cd $BUILDER_DIR
}

# packet modules
function menu_ext_packet(){
    ext_modules_targz
}

# Menu ext modules
function menu_extmodules(){
	OPTION=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --menu "Function List:" \
        --cancel-button "Return" \
        0 60 0 \
        "1" "Select" \
        "2" "Build" \
        "3" "Packet" \
        3>&1 1>&2 2>&3)
    
    if [ $OPTION ]; then
        case $OPTION in
            "1")
            menu_ext_select
            ;;
            "2")#
            menu_ext_build
            ext_modules_targz
            ;;
            "3")
            menu_ext_packet
            ;;
        esac
        menu_extmodules
    else
        menu_main
    fi
}

# Build objects config
# Check exists objects in OBJECTS config file
function check_exists_objects(){
    if [ -f $BUILDER_DIR"OBJECTS" ]; then
        OBJECTS_CURRENT=$(cat $BUILDER_DIR"OBJECTS")
        if [[ $OBJECTS_CURRENT == *"1"* ]]; then
            BUILD_PI1="ON"
        else
            BUILD_PI1="OFF"
        fi
        if [[ $OBJECTS_CURRENT == *"2"* ]]; then
            BUILD_PI2="ON"
        else
            BUILD_PI2="OFF"
        fi
        if [[ $OBJECTS_CURRENT == *"3"* ]]; then
            BUILD_PI4="ON"
        else
            BUILD_PI4="OFF"
        fi
        if [[ $OBJECTS_CURRENT == *"4"* ]]; then
            BUILD_PI3="ON"
        else
            BUILD_PI3="OFF"
        fi
        if [[ $OBJECTS_CURRENT == *"5"* ]]; then
            BUILD_PI4_64="ON"
        else
            BUILD_PI4_64="OFF"
        fi
    else
        OBJECTS_CURRENT='"1" "2" "3" "5"'
    fi
    
}

# Show objects menu
function menu_objects(){
    check_exists_objects
    if [ ! -f $BUILDER_DIR"OBJECTS" ]; then
        BUILD_PI1="ON"
        BUILD_PI2="ON"
        BUILD_PI4="ON"
        BUILD_PI3="OFF"
        BUILD_PI4_64="ON"
    fi
    OBJECTS_OPTION=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --checklist "Raspberry PI Modules:" \
        --cancel-button "Return" \
        0 60 0 \
        "1" "PI 1,CM 1 (bcmrpi_defconfig)" "$BUILD_PI1" \
        "2" "PI 2,3,CM 3 (bcm2709_defconfig)" "$BUILD_PI2" \
        "3" "PI 4,CM 4 (bcm2711_defconfig)" "$BUILD_PI4" \
        "4" "PI 3,CM 3 64bit (bcmrpi3_defconfig)" "$BUILD_PI3" \
        "5" "PI 4,CM 4 64bit (bcm2711_defconfig_64bit)" "$BUILD_PI4_64" \
        3>&1 1>&2 2>&3)
    if [ -f $BUILDER_DIR"OBJECTS" ]; then
        rm $BUILDER_DIR"OBJECTS"
    fi
    echo $OBJECTS_OPTION > $BUILDER_DIR"OBJECTS"
    check_exists_objects
}

# Main menu
function menu_main(){
	OPTION=$(whiptail --title "$MENU_TITLE" \
        --backtitle "$MENU_BG_TITLE" \
        --menu "Functin List:" \
        --cancel-button "Exit" \
        0 60 0 \
        "1" "Kernel Source" \
        "2" "Kernel Building" \
        "3" "External Modules Building" \
        "4" "PI Modules" \
        3>&1 1>&2 2>&3)
    
    if [ $OPTION ]; then
        case $OPTION in
            "1")
            menu_source
            ;;
            "2")#
            menu_kernel
            ;;
            "3")
            menu_extmodules
            ;;
            "4")
            menu_objects
            ;;
        esac
        menu_main
    else
        exit
    fi
}

# Init
function init(){
    check_arch
    check_system_required
    check_cpu_num
    get_exists_tag
    check_exists_objects
    check_exists_hash
    check_exists_extmodules
}

init
# menu_ext_build
# exit
menu_main

