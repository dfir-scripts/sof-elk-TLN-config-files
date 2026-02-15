# Integrating TLN Timelines into SOF-ELK

This document provides instructions for integrating TLN (Harlan Carvey) timeline support into the SOF-ELK (Phil Hagen) virtual machine. The provided configuration files are designed to be compatible with modern Elastic Stack versions and follow SOF-ELK's modular architecture.

## Overview

The integration uses Filebeat to monitor for TLN files (case-insensitive), Logstash to parse and enrich the data, and Elasticsearch to store and index the timelines. The data is then available for analysis in Kibana.

### Supported TLN Formats

This integration supports two TLN format variants:

1. **Pipe-delimited with epoch timestamp** (original format)
   ```
   1123619888|EVT|PETER|S-1-5-18|Description
   ```

2. **Comma-delimited with formatted timestamp** (YYYY-MM-DD HH:MM:SS)
   ```
   2005-08-10 01:04:48,EVT,PETER,S-1-5-18,Description
   ```

Both formats are automatically detected and parsed correctly. File extensions are matched case-insensitively:
- `.tln`, `.TLN`, `.Tln` (any case variation)
- `.csv`, `.CSV`, `.Csv` (any case variation)

## Included Files

The following configuration files are provided:

- `filebeat-tln.yml`: Filebeat input configuration
- `1100-preprocess-tln.conf`: Logstash preprocessing configuration
- `6675-tln.conf`: Logstash main parsing and filtering configuration (uses dissect filter for optimal performance)
- `9999-output-tln.conf`: Logstash output configuration to route TLN data to tln-* indices
- `tln-template.json`: Elasticsearch index template

## Deployment Instructions

### 1. Deploy Filebeat Configuration

Copy the `filebeat-tln.yml` file to the SOF-ELK Filebeat inputs directory.

```bash
sudo cp filebeat-tln.yml /usr/local/sof-elk/lib/filebeat_inputs/tln.yml
```

### 2. Deploy Logstash Configuration Files

Following the SOF-ELK convention, copy the configuration files to `/usr/local/sof-elk/configfiles/` and create symbolic links in `/etc/logstash/conf.d/`.

```bash
# Copy files to the SOF-ELK configfiles directory
sudo cp 1100-preprocess-tln.conf /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf
sudo cp 6675-tln.conf /usr/local/sof-elk/configfiles/6675-tln.conf
sudo cp 9999-output-tln.conf /usr/local/sof-elk/configfiles/9999-output-tln.conf

# Create symbolic links in the Logstash conf.d directory
sudo ln -s /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf /etc/logstash/conf.d/1100-preprocess-tln.conf
sudo ln -s /usr/local/sof-elk/configfiles/6675-tln.conf /etc/logstash/conf.d/6675-tln.conf
sudo ln -s /usr/local/sof-elk/configfiles/9999-output-tln.conf /etc/logstash/conf.d/9999-output-tln.conf
```

### 3. Deploy Elasticsearch Index Template

Install the Elasticsearch index template using the `curl` command.

```bash
curl -X PUT "http://localhost:9200/_index_template/tln_template" -H "Content-Type: application/json" -d @tln-template.json
```

### 4. Restart Services

Restart the Filebeat and Logstash services to apply the new configurations.

```bash
sudo systemctl restart filebeat
sudo systemctl restart logstash
```

## Testing the Integration

To test the integration, you can create a sample TLN file and place it in the directory monitored by Filebeat (`/logstash/tln/`).

### Sample TLN File

Create a file named `sample.tln` with the following content:

```
1123619888|EVT|PETER|S-1-5-18|Userenv/1517;EVENTLOG_WARNING_TYPE;PETER\Harlan
1644492800|REG|WORKSTATION1|jdoe|HKCU\Software\Microsoft\Windows\CurrentVersion\Run|OneDrive
```

Place this file in the `/logstash/tln/` directory.

### Verification

After a few moments, the data should be visible in Kibana. You can verify this by creating a new index pattern for `tln-*` and exploring the data in the Discover tab.

## Notes

- The Filebeat configuration assumes that your TLN files will be placed in the `/logstash/tln/` directory. You can modify the `paths` in `filebeat-tln.yml` to match your environment.
- The Logstash configurations follow the SOF-ELK symbolic link convention with original files stored at `/usr/local/sof-elk/configfiles/`.
- The Elasticsearch index template is designed to provide optimal performance for timeline analysis.
- Configuration file `7765-tln.conf` is numbered to fit within the SOF-ELK pipeline processing order.
