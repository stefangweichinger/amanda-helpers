# Make slots as specified on the command line.

# syntax: makeslots <config> start stop

# Where start and stop are the slot numbers to create. They should
# continue from the last that already exists. Gaps do you no good.

config=$1

if [ "$config" = "-h" ] || [ "$config" = "--help" ] \
       || [ $# != 3 ] ; then
    echo makeslots: config start stop
    exit
fi

path=$(gettapedev.pl ${config})

if [ $? != '0' ] ; then
    echo Path ${path} is invalid!
    exit
fi

cd ${path}

if [ $? != '0' ] ; then
    echo Path ${path} is invalid!
    exit
fi

for i in $(seq $2 $3 ) ; do
   echo $i ;
   if [ -e slot$i ] ; then
     echo "slot$i exists. Not making it."
   else
     mkdir -p slot$i
     chmod 0700 slot$i          # privacy & security.
     amlabel ${config} ${config}_$( printf %02d $i) slot $i
   fi
done
