#!/bin/bash
#This script shall be with 'set execution id' to root or 
#include this script to the sudoers without password as 
#it is called from inside the device when there is an 
#specific usb exception.

if [[ $EUID != 0 ]] ; then
  echo This must be run as root!
  exit 1
fi

for xhci in /sys/bus/pci/drivers/?hci_hcd ; do

  if ! cd $xhci ; then
    echo Weird error. Failed to change directory to $xhci
    exit 1
  fi

  echo Resetting devices from $xhci...

  for i in ????:??:??.? ; do
    echo Reseting usb $i
    echo -n "$i" > unbind
    echo -n "$i" > bind
  done
done
