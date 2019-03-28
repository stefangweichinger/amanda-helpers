#!/bin/bash

# Stefan G. Weichinger, 2019

# helper script for amanda backup
# it reads the inventory of a config, compares it to the needed tapes for the next runs
# and reports back the differences:

# which tapes are missing
# which tapes can be removed from the robot

# WIP: still hardcoded, test comments still inside

diff(){
  awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}

ARRAY_INVENTORY=( $(/usr/sbin/amtape daily inventory))
ARRAY_WANTED=( $(/usr/sbin/amadmin daily tape --days 2))

#for element in $(seq 0 $((${#ARRAY_EXAMPLE[@]} - 1)));
#  do                #  ${#script_contents[@]}
#                    #+ gives number of elements in the array.
#                    #
#                    #  Question:
#                    #  Why is  seq 0  necessary?
#                    #  Try changing it to seq 1.
#  echo -n "${ARRAY_EXAMPLE[$element]}"
#                    # List each field of this script on a single line.
## echo -n "${script_contents[element]}" also works because of ${ ... }.
#  echo -n " -- "    # Use " -- " as a field separator.
#done

regex="CMR([0-9]+)"
regex1="CMR([0-9]+)[[:space:]]"
#regex1="CMR([0-9]+)\s"

#declare -p ARRAY_WANTED
#declare -p ARRAY_INVENTORY

for element in $(seq 0 $((${#ARRAY_WANTED[@]} - 1))); do 
if [[ ${ARRAY_WANTED[element]} =~ $regex ]]
then
:
#echo "match!"
	#echo -n "${ARRAY_WANTED[element]}"
	#echo -n " -- "    # Use " -- " as a field separator.
  else
  unset 'ARRAY_WANTED[element]'
fi
done

for element in $(seq 0 $((${#ARRAY_INVENTORY[@]} - 1))); do 
if [[ ${ARRAY_INVENTORY[element]} =~ $regex ]]
then
:
#echo "match!"
	#echo -n "${ARRAY_INVENTORY[element]}"
	#echo -n " -- "    # Use " -- " as a field separator.
  else
  unset 'ARRAY_INVENTORY[element]'
fi
done

#declare -p ARRAY_WANTED
#declare -p ARRAY_INVENTORY

Array3=()
for i in "${ARRAY_WANTED[@]}"; do
    skip=
    for j in "${ARRAY_INVENTORY[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || Array3+=("$i")
done
#declare -p Array3

# loop ueber INVENTORY: wird das tape $i auch WANTED?

Array4=()
for i in "${ARRAY_INVENTORY[@]}"; do
    skip=
    i=${i%L6}
    for j in "${ARRAY_WANTED[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || Array4+=("$i")
done
#declare -p Array4

uniq=($(printf "%s\n" "${Array4[@]}" | sort -u));


# report the missing tapes
echo "--- BETA-script 2019 ---"
echo "  "
echo "Es fehlen: "
echo "${Array3[@]}"

# report the tapes which can be removed from the changer
echo "Raus muessen: "
echo "${uniq[@]}"

#Array4=($(diff ARRAY_WANTED[@] ARRAY_INVENTORY[@]))
#declare -p Array4

#Array5=($(diff ARRAY_INVENTORY[@] ARRAY_WANTED[@]))
#declare -p Array5

#Array6=( "${ARRAY_WANTED[@]/$ARRAY_INVENTORY}" )
#declare -p Array6

#if
#[[ $var1 =~ $regex ]]
#then
# echo "match"
#  echo "${BASH_REMATCH[0]}"
#  echo "${BASH_REMATCH[1]}"
#  else
#  echo "no match"
#  fi
#
