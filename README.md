# sof-elk-TLN-config-files

These config files provide support for TLN files in SANS Sof-Elk

Copy the files from this repository into the following directories:<br>
/usr/local/sof-elk/configfiles/6601-tln.conf<br>
/usr/local/sof-elk/configfiles/9304-output-tln.conf<br>
/usr/local/sof-elk/lib/file-beat-inputs/tln.yml<br>
/usr/local/sof-elk/lib/elasticsearch-tln-template.json<br><br>


Enter the following commands to create directories and symbolic links:<br>

ln -s  /usr/local/sof-elk/configfiles/6601-tln.conf /etc/logstash/config.d/6601-tln.conf<br>
ln -s  /usr/local/sof-elk/configfiles/9304-output-tln.conf   /etc/logstash/config.d/9304-output-tln.conf<br>
 mkdir /logstash/tln<br>
chmod 7777 /logstash/tln<br>

Copy TLN files from regripper or other sources to the directory:  /logstash/tln/

Create Dashboards as needed
