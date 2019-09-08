nwstatus=""
for ifname in $(ifconfig -l); do
    ifstatus=$(ifconfig ${ifname} | grep status | cut -f 2 -d " ");
    
    [[ "${ifstatus}" == "" ]] && continue;

    hwport=$(networksetup -listallhardwareports | grep -B 1 ${ifname} | head -n 1 | cut -f 2 -d ":")
    
    [[ "${hwport}" == "" ]] && continue;
    
    [[ "${ifstatus}" != "active" ]] && continue;

    statuschar="✓"
    nwstatus="${nwstatus} ${hwport}: ${statuschar}" 
done

[[ ${nwstatus} == "" ]] && echo "(offline)" || echo ${nwstatus}
