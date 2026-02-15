#!/bin/bash
#
# TLN Timeline Integration Installer for SOF-ELK
# This script automates the deployment of TLN timeline support
#
# Usage: sudo ./install-tln.sh [options]
#   -h, --help     Show this help message
#   -d, --dir      Specify source directory (default: current directory)
#   -y, --yes      Skip confirmation prompts
#

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SOURCE_DIR="$(pwd)"
SKIP_CONFIRM=false

# Function to display help
show_help() {
    echo "TLN Timeline Integration Installer for SOF-ELK"
    echo ""
    echo "Usage: sudo $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -d, --dir DIR  Specify source directory containing config files (default: current directory)"
    echo "  -y, --yes      Skip confirmation prompts"
    echo ""
    echo "Example:"
    echo "  sudo $0 -d /home/elk_user/tln-config"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if required files exist
check_files() {
    local missing_files=()
    
    if [[ ! -f "$SOURCE_DIR/filebeat-tln.yml" ]]; then
        missing_files+=("filebeat-tln.yml")
    fi
    
    if [[ ! -f "$SOURCE_DIR/1100-preprocess-tln.conf" ]]; then
        missing_files+=("1100-preprocess-tln.conf")
    fi
    
    if [[ ! -f "$SOURCE_DIR/6675-tln.conf" ]]; then
        missing_files+=("6675-tln.conf")
    fi
    
    if [[ ! -f "$SOURCE_DIR/9999-output-tln.conf" ]]; then
        missing_files+=("9999-output-tln.conf")
    fi
    
    if [[ ! -f "$SOURCE_DIR/tln-template.json" ]]; then
        missing_files+=("tln-template.json")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files in $SOURCE_DIR:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
}

# Function to check if required SOF-ELK directories exist
check_sofelk_directories() {
    local missing_dirs=()
    
    if [[ ! -d "/usr/local/sof-elk/configfiles" ]]; then
        missing_dirs+=("/usr/local/sof-elk/configfiles")
    fi
    
    if [[ ! -d "/usr/local/sof-elk/lib/filebeat_inputs" ]]; then
        missing_dirs+=("/usr/local/sof-elk/lib/filebeat_inputs")
    fi
    
    if [[ ! -d "/etc/logstash/conf.d" ]]; then
        missing_dirs+=("/etc/logstash/conf.d")
    fi
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        print_error "Required SOF-ELK directories do not exist. This script requires a properly configured SOF-ELK installation."
        print_error "Missing directories:"
        for dir in "${missing_dirs[@]}"; do
            echo "  - $dir"
        done
        exit 1
    fi
}

# Function to create TLN data directory
create_tln_directory() {
    print_info "Creating TLN data directory..."
    
    if [[ ! -d "/logstash/tln" ]]; then
        mkdir -p /logstash/tln
        chmod 777 /logstash/tln
        print_success "Created /logstash/tln directory with permissions 777"
    else
        print_info "Directory /logstash/tln already exists"
        chmod 777 /logstash/tln
        print_success "Updated /logstash/tln permissions to 777"
    fi
}

# Function to check if services exist
check_services() {
    if ! systemctl list-unit-files | grep -q "^filebeat.service"; then
        print_warning "Filebeat service not found. Please ensure Filebeat is installed."
    fi
    
    if ! systemctl list-unit-files | grep -q "^logstash.service"; then
        print_warning "Logstash service not found. Please ensure Logstash is installed."
    fi
}

# Function to create backup of existing files
create_backup() {
    local backup_dir="/usr/local/sof-elk/configfiles/backups/tln-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -f "/usr/local/sof-elk/configfiles/1100-preprocess-tln.conf" ]] || \
       [[ -f "/usr/local/sof-elk/configfiles/6675-tln.conf" ]]; then
        print_info "Creating backup of existing TLN configuration files..."
        mkdir -p "$backup_dir"
        
        if [[ -f "/usr/local/sof-elk/configfiles/1100-preprocess-tln.conf" ]]; then
            cp "/usr/local/sof-elk/configfiles/1100-preprocess-tln.conf" "$backup_dir/"
        fi
        
        if [[ -f "/usr/local/sof-elk/configfiles/6675-tln.conf" ]]; then
            cp "/usr/local/sof-elk/configfiles/6675-tln.conf" "$backup_dir/"
        fi
        
        if [[ -f "/usr/local/sof-elk/configfiles/9999-output-tln.conf" ]]; then
            cp "/usr/local/sof-elk/configfiles/9999-output-tln.conf" "$backup_dir/"
        fi
        
        print_success "Backup created at: $backup_dir"
    fi
}

# Function to deploy Filebeat configuration
deploy_filebeat() {
    print_info "Deploying Filebeat configuration..."
    
    # Copy configuration file to SOF-ELK filebeat_inputs directory
    cp "$SOURCE_DIR/filebeat-tln.yml" /usr/local/sof-elk/lib/filebeat_inputs/tln.yml
    chmod 644 /usr/local/sof-elk/lib/filebeat_inputs/tln.yml
    
    print_success "Filebeat configuration deployed to /usr/local/sof-elk/lib/filebeat_inputs/tln.yml"
}

# Function to deploy Logstash configurations
deploy_logstash() {
    print_info "Deploying Logstash configuration files..."
    
    # Copy configuration files to SOF-ELK directory
    cp "$SOURCE_DIR/1100-preprocess-tln.conf" /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf
    cp "$SOURCE_DIR/6675-tln.conf" /usr/local/sof-elk/configfiles/6675-tln.conf
    cp "$SOURCE_DIR/9999-output-tln.conf" /usr/local/sof-elk/configfiles/9999-output-tln.conf
    
    # Set ownership and permissions
    chown logstash:logstash /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf
    chown logstash:logstash /usr/local/sof-elk/configfiles/6675-tln.conf
    chown logstash:logstash /usr/local/sof-elk/configfiles/9999-output-tln.conf
    chmod 644 /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf
    chmod 644 /usr/local/sof-elk/configfiles/6675-tln.conf
    chmod 644 /usr/local/sof-elk/configfiles/9999-output-tln.conf
    
    print_success "Configuration files copied to /usr/local/sof-elk/configfiles/"
    
    # Create symbolic links
    print_info "Creating symbolic links in /etc/logstash/conf.d/..."
    
    # Remove existing symlinks if they exist
    if [[ -L "/etc/logstash/conf.d/1100-preprocess-tln.conf" ]]; then
        rm -f /etc/logstash/conf.d/1100-preprocess-tln.conf
    fi
    
    if [[ -L "/etc/logstash/conf.d/6675-tln.conf" ]]; then
        rm -f /etc/logstash/conf.d/6675-tln.conf
    fi
    
    if [[ -L "/etc/logstash/conf.d/9999-output-tln.conf" ]]; then
        rm -f /etc/logstash/conf.d/9999-output-tln.conf
    fi
    
    # Create new symbolic links
    ln -s /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf /etc/logstash/conf.d/1100-preprocess-tln.conf
    ln -s /usr/local/sof-elk/configfiles/6675-tln.conf /etc/logstash/conf.d/6675-tln.conf
    ln -s /usr/local/sof-elk/configfiles/9999-output-tln.conf /etc/logstash/conf.d/9999-output-tln.conf
    
    print_success "Symbolic links created in /etc/logstash/conf.d/"
}

# Function to verify Logstash configuration
verify_logstash_config() {
    print_info "Verifying Logstash configuration syntax..."
    
    if sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash --config.test_and_exit -f /etc/logstash/conf.d/ > /dev/null 2>&1; then
        print_success "Logstash configuration syntax is valid"
        return 0
    else
        print_error "Logstash configuration syntax check failed"
        print_warning "Run manually to see errors:"
        print_warning "  sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash --config.test_and_exit -f /etc/logstash/conf.d/"
        return 1
    fi
}

# Function to deploy Elasticsearch index template
deploy_elasticsearch_template() {
    print_info "Deploying Elasticsearch index template..."
    
    # Check if Elasticsearch is running
    if ! curl -s -f "http://localhost:9200" > /dev/null 2>&1; then
        print_warning "Elasticsearch does not appear to be running on localhost:9200"
        print_warning "Skipping index template deployment. Deploy manually with:"
        print_warning "  curl -X PUT \"http://localhost:9200/_index_template/tln_template\" -H \"Content-Type: application/json\" -d @$SOURCE_DIR/tln-template.json"
        return 1
    fi
    
    # Deploy the template
    if curl -X PUT "http://localhost:9200/_index_template/tln_template" \
         -H "Content-Type: application/json" \
         -d @"$SOURCE_DIR/tln-template.json" \
         -s -f > /dev/null 2>&1; then
        print_success "Elasticsearch index template deployed successfully"
        return 0
    else
        print_error "Failed to deploy Elasticsearch index template"
        print_warning "Deploy manually with:"
        print_warning "  curl -X PUT \"http://localhost:9200/_index_template/tln_template\" -H \"Content-Type: application/json\" -d @$SOURCE_DIR/tln-template.json"
        return 1
    fi
}

# Function to restart services
restart_services() {
    print_info "Restarting services..."
    
    # Restart Filebeat
    if systemctl list-unit-files | grep -q "^filebeat.service"; then
        print_info "Restarting Filebeat..."
        if systemctl restart filebeat; then
            print_success "Filebeat restarted successfully"
        else
            print_error "Failed to restart Filebeat"
        fi
    fi
    
    # Restart Logstash
    if systemctl list-unit-files | grep -q "^logstash.service"; then
        print_info "Restarting Logstash (this may take a moment)..."
        if systemctl restart logstash; then
            print_success "Logstash restarted successfully"
        else
            print_error "Failed to restart Logstash"
        fi
    fi
}

# Function to display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "  TLN Integration Installation Complete"
    echo "=========================================="
    echo ""
    echo "Configuration files installed:"
    echo "  • Filebeat: /usr/local/sof-elk/lib/filebeat_inputs/tln.yml"
    echo "  • Logstash: /usr/local/sof-elk/configfiles/1100-preprocess-tln.conf"
    echo "  • Logstash: /usr/local/sof-elk/configfiles/6675-tln.conf"
    echo "  • Logstash: /usr/local/sof-elk/configfiles/9999-output-tln.conf"
    echo "  • Symlinks: /etc/logstash/conf.d/"
    echo ""
    echo "Next steps:"
    echo "  1. Place TLN files in /logstash/tln/"
    echo "  2. Monitor ingestion with: sudo journalctl -u filebeat -f"
    echo "  3. Check Logstash logs: sudo journalctl -u logstash -f"
    echo "  4. Create Kibana index pattern for 'tln-*'"
    echo ""
    echo "For testing, you can use the provided sample.tln file:"
    if [[ -f "$SOURCE_DIR/sample.tln" ]]; then
        echo "  sudo cp $SOURCE_DIR/sample.tln /logstash/tln/"
    fi
    echo ""
    echo "========================================"
    echo "  Common Troubleshooting Commands"
    echo "========================================"
    echo ""
    echo "Check service status:"
    echo "  sudo systemctl status filebeat"
    echo "  sudo systemctl status logstash"
    echo "  sudo systemctl status elasticsearch"
    echo ""
    echo "View service logs:"
    echo "  sudo journalctl -u filebeat -n 50 --no-pager"
    echo "  sudo journalctl -u logstash -n 50 --no-pager"
    echo ""
    echo "Test Logstash configuration:"
    echo "  sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash --config.test_and_exit -f /etc/logstash/conf.d/"
    echo ""
    echo "Check Filebeat registry (what files have been processed):"
    echo "  sudo filebeat registry list"
    echo ""
    echo "Check Elasticsearch indices:"
    echo "  curl -s http://localhost:9200/_cat/indices/tln-*?v"
    echo ""
    echo "Search for TLN events in Elasticsearch:"
    echo "  curl -s http://localhost:9200/tln-*/_search?size=5 | jq ."
    echo ""
    echo "Check for parsing errors (tagged events):"
    echo "  curl -s 'http://localhost:9200/tln-*/_search?q=tags:tln_parse_error&size=5' | jq ."
    echo ""
    echo "NOTE: Sample files must be at least 1KB (1024 bytes) for Filebeat 9.0 to process them."
    echo "      All provided sample files exceed 2KB to ensure compatibility."
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "=========================================="
    echo "  TLN Timeline Integration Installer"
    echo "  for SOF-ELK"
    echo "=========================================="
    echo ""
    
    # Pre-flight checks
    check_root
    print_info "Source directory: $SOURCE_DIR"
    check_files
    check_sofelk_directories
    check_services
    
    # Create TLN directory first
    create_tln_directory
    
    # Confirmation prompt
    if [[ "$SKIP_CONFIRM" == false ]]; then
        echo ""
        echo "This script will:"
        echo "  • Create /logstash/tln directory"
        echo "  • Deploy Filebeat configuration"
        echo "  • Deploy Logstash configuration files"
        echo "  • Create symbolic links"
        echo "  • Deploy Elasticsearch index template"
        echo "  • Restart Filebeat and Logstash services"
        echo ""
        read -p "Continue with installation? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    
    # Create backup if existing configs found
    create_backup
    
    # Deploy configurations
    deploy_filebeat
    deploy_logstash
    
    # Verify Logstash configuration
    if ! verify_logstash_config; then
        print_warning "Logstash configuration verification failed. Continuing anyway..."
    fi
    
    # Deploy Elasticsearch template
    deploy_elasticsearch_template
    
    # Restart services
    restart_services
    
    # Display summary
    display_summary
    
    print_success "Installation completed successfully!"
}

# Run main function
main
