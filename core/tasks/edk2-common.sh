#
# Declare bits for PcdDebugPropertyMask
#
DEBUG_PROPERTY_DEBUG_ASSERT_ENABLED=0x01
DEBUG_PROPERTY_DEBUG_PRINT_ENABLED=0x02
DEBUG_PROPERTY_DEBUG_CODE_ENABLED=0x04
DEBUG_PROPERTY_CLEAR_MEMORY_ENABLED=0x08
DEBUG_PROPERTY_ASSERT_BREAKPOINT_ENABLED=0x10
DEBUG_PROPERTY_ASSERT_DEADLOOP_ENABLED=0x20

#
# Declare bits for PcdDebugPrintErrorLevel and the ErrorLevel parameter of DebugPrint()
#
DEBUG_INIT=0x00000001     # Initialization
DEBUG_WARN=0x00000002     # Warnings
DEBUG_LOAD=0x00000004     # Load events
DEBUG_FS=0x00000008       # EFI File system
DEBUG_POOL=0x00000010     # Alloc & Free's
DEBUG_PAGE=0x00000020     # Alloc & Free's
DEBUG_INFO=0x00000040     # Informational debug messages
DEBUG_DISPATCH=0x00000080 # PEI/DXE/SMM Dispatchers
DEBUG_VARIABLE=0x00000100 # Variable
DEBUG_BM=0x00000400       # Boot Manager
DEBUG_BLKIO=0x00001000    # BlkIo Driver
DEBUG_NET=0x00004000      # SNI Driver
DEBUG_UNDI=0x00010000     # UNDI Driver
DEBUG_LOADFILE=0x00020000 # UNDI Driver
DEBUG_EVENT=0x00080000    # Event messages
DEBUG_GCD=0x00100000      # Global Coherency Database changes
DEBUG_CACHE=0x00200000    # Memory range cachability changes
DEBUG_VERBOSE=0x00400000  # Detailed debug messages that may significantly impact boot performance
DEBUG_ERROR=0x80000000    # Error

setflag_printlevel() {
    FLAGS="$1"

    EDK2_PRINT_ERROR_LEVEL=$(printf "0x%x" $(( $EDK2_PRINT_ERROR_LEVEL | $FLAGS )) )
}

setflag_propertymask() {
    FLAGS="$1"

    EDK2_PROPERTY_MASK=$(printf "0x%x" $(( $EDK2_PROPERTY_MASK | $FLAGS )) )
}

EDK2_OUT="$MODULE_OUT"
EDK2_DIR="$TOP/uefi/edk2"
EDK2_ENV="MAKEFLAGS="
EDK2_COMPILER="GCC49"
EDK2_PRINT_ERROR_LEVEL="0"
EDK2_PROPERTY_MASK="0"

if [ "$EFIDROID_TARGET_ARCH" == "arm" ];then
    EDK2_ARCH="ARM"
elif [ "$EFIDROID_TARGET_ARCH" == "x86" ];then
    EDK2_ARCH="IA32"
elif [ "$EFIDROID_TARGET_ARCH" == "x86_64" ];then
    EDK2_ARCH="X64"
elif [ "$EFIDROID_TARGET_ARCH" == "aarch64" ];then
    EDK2_ARCH="AArch64"
fi
EDK2_ENV="$EDK2_ENV ${EDK2_COMPILER}_${EDK2_ARCH}_PREFIX=$GCC_NONE_TARGET_PREFIX"

CompileEDK2() {
    PROJECTCONFIG="$1"
    DEFINES="$2"

    # get number of jobs
    MAKEPATH=$($MAKEFORWARD_PIPES)
    plussigns=$(timeout -k 1 1 cat "$MAKEPATH/3" ; exit 0)
    numjobs=$(($(echo -n $plussigns | wc -c) + 1))

    # compile EDKII
    "$EFIDROID_SHELL" -c "\
	    cd "$EDK2_OUT" && \
		    source edksetup.sh && \
		    $EDK2_ENV build -n$numjobs -b ${EDK2_BUILD_TYPE} -a ${EDK2_ARCH} -t ${EDK2_COMPILER} -p ${PROJECTCONFIG} \
                ${DEFINES} \
    " 2> >(\
    while read line; do \
        if [[ "$line" =~ "error" ]];then \
            echo -e "\e[01;31m$line\e[0m" >&2; \
        else \
            echo -e "\e[01;32m$line\e[0m" >&2; \
        fi;\
    done)

    # write back our jobs
    echo -n "$plussigns" > "$MAKEPATH/3"
}

EDK2Shell() {
    "$EFIDROID_SHELL" -c "\
        cd \"$EDK2_OUT\" && \
		    source edksetup.sh && \
		    $EDK2_ENV \"$EFIDROID_SHELL\" \
    "
}