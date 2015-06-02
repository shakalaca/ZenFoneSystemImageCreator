CHOWN='chown'
CHMOD='chmod'
FIND='find'
LINK='ln -s'

set_perm_recursive() {
        TARGET=${5:1}
#        $CHOWN -R $1:$2 $TARGET
#        $FIND $TARGET -type d -exec chmod $3 {} +
#        $FIND $TARGET -type f -exec chmod $4 {} +
}

set_perm() {
        TARGET=${4:1}
#        $CHOWN $1:$2 $TARGET
#        $CHMOD $3 $TARGET
}

set_metadata_recursive() {
        TARGET=${1:1}
#        $CHOWN -R $2:$3 $TARGET
#        $FIND $TARGET -type d -exec chmod $4 {} +
#        $FIND $TARGET -type f -exec chmod $5 {} +
}

set_metadata() {
        TARGET=${1:1}
#        $CHOWN $2:$3 $TARGET
#        $CHMOD $4 $TARGET
}

symlink() {
        SOURCE=$1
        shift
        for TARGET in "$@"
        do
        	TARGET=${TARGET:1}
                XPATH=${TARGET%/*}
                XFILE=${TARGET##*/}
                
                if [ ! -d $XPATH ]; then
                        mkdir -p $XPATH
                fi

                pushd $XPATH
                $LINK $SOURCE $XFILE
                popd
        done
}
