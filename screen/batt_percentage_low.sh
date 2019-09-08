mydir=`dirname $0`
bat=`${mydir}/batt_percentage.sh`

if [[ $bat -lt 30 ]]; then
    echo $bat
else
    exit
fi
