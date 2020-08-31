# sof-elk-TLN-config-files

Config files provide support for TLN files in SANS Sof-Elk
### From Sof-ELK terminal
<b>Copy the files from this repository into the following directories:<b><br>
/usr/local/sof-elk/configfiles/6601-tln.conf<br>
/usr/local/sof-elk/configfiles/9304-output-tln.conf<br>
/usr/local/sof-elk/lib/file-beat-inputs/tln.yml<br>
/usr/local/sof-elk/lib/elasticsearch-tln-template.json<br><br>


<b>Enter the following commands to create directories and symbolic links:<br><b>

ln -s  /usr/local/sof-elk/configfiles/6601-tln.conf /etc/logstash/config.d/6601-tln.conf<br>
ln -s  /usr/local/sof-elk/configfiles/9304-output-tln.conf   /etc/logstash/config.d/9304-output-tln.conf<br>
 mkdir /logstash/tln<br>
chmod 7777 /logstash/tln<br>

Copy TLN files from regripper or other sources to the directory:  /logstash/tln/

### From Kibana Import Saved Dashboards
Objects > Saved Objects > Import > TLN-Dashboard.json<br>
Load TLN_DATA Dashboard to view data
