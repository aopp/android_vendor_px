BASEDIR=$(dirname $0)
PRODUCT_PATH=$1
echo $PRODUCT_PATH
mkdir -p $PRODUCT_PATH/system/app/TerminalEmulator/lib/arm/
cp -a $BASEDIR/lib/arm/* $PRODUCT_PATH/system/app/TerminalEmulator/lib/arm/
