#!/bin/bash

cat $1 | sed 's/        /symlink("toolbox", /' > pass1

grep 'symlink\|set_metadata' pass1 > pass2

cat pass2 | sed -e 's/symlink(\"/symlink /' -e 's/set_metadata_recursive(\"/set_metadata_recursive /' -e 's/set_metadata(\"/set_metadata /' > pass3

cat pass3 | sed -e 's/\", \"uid\",//' -e 's/, \"gid\",//' -e 's/, \"dmode\",//' -e 's/, \"fmode\",//' -e 's/, \"mode\",//' > pass4

cat pass4 | sed -e 's/\", \"/ /g' -e 's/\");//' -e 's/\",//' > pass5

awk -F , '{print $1}' pass5  > pass6

echo "#!/bin/bash

source ../scripts/func.bash
" > $2
cat pass6 >> $2
rm pass*

chmod 755 $2
