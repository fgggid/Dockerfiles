
__author__ = "Ameen Ali - @rootameen"

import xml.etree.ElementTree as ET
from prettytable import PrettyTable
import os

vm_info = PrettyTable()
vm_info.field_names = ["Compute Node", "VM Name",
                       "VM IP Address", "VM MAC Address", "VM Metadata Address"]


os.popen('curl -s http://localhost:9083/Snh_BgpNeighborReq | xmllint --format - > /tmp/.control.xml')

control_tree = ET.parse('/tmp/.control.xml')
control_root = control_tree.getroot()

vrouter_names = []

for vrouter in control_root.iter('BgpNeighborResp'):
    vrouter_ip = vrouter.find('peer_address').text
    vrouter_name = vrouter.find('peer').text
    encoding_type = vrouter.find('encoding').text
    if encoding_type == "XMPP":
        vrouter_names.append(vrouter_name)
        os.popen('curl -s http://' + vrouter_ip +
                 ':8085/Snh_ItfReq| xmllint --format - > ' + vrouter_name + '.xml')


for vrouter in vrouter_names:
    compute_tree = ET.parse(vrouter + '.xml')
    compute_root = compute_tree.getroot()

    for interface in compute_root.iter('ItfSandeshData'):
        vm_name = interface.find('vm_name').text
        ip_addr = interface.find('ip_addr').text
        mac_addr = interface.find('mac_addr').text
        mdata_ip_addr = interface.find('mdata_ip_addr').text
        if vm_name is not None:
            vm_info.add_row(
                [vrouter, vm_name, ip_addr, mac_addr, mdata_ip_addr])

print vm_info
