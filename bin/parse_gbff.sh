#!/bin/bash
set -e

field=
state=0
translation=0

while IFS="" read -r row || [ -n "$row" ]
do
  if [ "$state" == "0" ] && [[ "$row" =~ ^FEATURES\ .*$ ]]
  then
    state=1
    continue
  fi

  if [ "$state" == "1" ] && [[ "$row" =~ ^\ {5}[a-zA-Z]+\ .*$ ]]
  then
    echo "$row" | awk '{$1=$1};1'
    state=2
    continue
  fi

  if [ "$state" == "2" ] && [[ "$row" =~ ^\ +\/.*$ ]]
  then
    [[ "$row" =~ ^\ +\/translation.*$ ]] && translation=1 || translation=0
    field=$(echo "$row" | awk '{$1=$1};1')
    state=3
    continue
  fi

  if [ "$state" == "3" ] && [[ "$row" =~ ^\ {5}[a-zA-Z]+\ .*$ ]]
  then
    echo "  $field"
    field=
    echo "$row" | awk '{$1=$1};1'
    state=2
    continue
  fi

  if [ "$state" == "3" ] && [[ "$row" =~ ^\ +\/.*$ ]]
  then
    [[ "$row" =~ ^\ +\/translation.*$ ]] && translation=1 || translation=0
    echo "  $field"
    field=
    field=$(echo "$row" | awk '{$1=$1};1')
    state=3
    continue
  fi

  if [ "$state" != "0" ] && [[ "$row" =~ ^CONTIG\ .*$ ]]
  then
    echo "  $field"
    echo "$row" | awk '{$1=$1};1'
    state=4
    continue
  fi

  if [ "$state" != "0" ] && [[ "$row" =~ ^ORIGIN$ ]]
  then
    echo "$row" | awk '{$1=$1};1'
    state=4
    exit 0
  fi

  if [ "$state" == "3" ]
  then
    [ "$translation" == "0" ] && field="$field "
    field=$field$(echo "$row" | awk '{$1=$1};1')
    state=3
    continue
  fi
done <GCF_001458655.1_Mb9_genomic.gbff
