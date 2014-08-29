CHOWN='chown'
CHMOD='chmod'
FIND='find'
LINK='ln -s'

set_perm_recursive() {
        TARGET=${5:1}
        $CHOWN -R $1:$2 $TARGET
#        $CHOWN -R $1.$2 $TARGET
        $FIND $TARGET -type d -exec chmod $3 {} +
        $FIND $TARGET -type f -exec chmod $4 {} +
}

set_perm() {
        TARGET=${4:1}
        $CHOWN $1:$2 $TARGET
#        $CHOWN $1.$2 $TARGET
        $CHMOD $3 $TARGET
}

symlink() {
        SOURCE=$1
        shift
        for TARGET in "$@"
        do
        	TARGET=${TARGET:1}
                XPATH=${TARGET%/*}
                XFILE=${TARGET##*/}

                pushd $XPATH
                $LINK $SOURCE $XFILE
                popd
        done
}
