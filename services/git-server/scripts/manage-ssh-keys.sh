#!/bin/bash
# SSH Key Management Script for GitLab
# Provides commands to add, list, and delete SSH keys for users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GitLab is running
check_gitlab_running() {
    if ! docker compose ps git-server --status running --format json | grep -q '"State":"running"'; then
        print_error "GitLab container is not running"
        exit 1
    fi
}

# List SSH keys for a user
list_keys() {
    local username=$1

    if [ -z "$username" ]; then
        print_error "Usage: $0 list <username>"
        exit 1
    fi

    print_info "Listing SSH keys for user: $username"
    docker compose exec -T -e USERNAME="$username" git-server gitlab-rails runner << 'EOF'
user = User.find_by(username: ENV['USERNAME'])
if user
  user.keys.each do |key|
    puts "ID: #{key.id}, Title: #{key.title}, Fingerprint: #{key.fingerprint}"
  end
else
  puts "Error: User not found"
  exit 1
end
EOF
}

# Add an SSH key for a user
add_key() {
    local username=$1
    local title=$2
    local key_content=$3

    if [ -z "$username" ] || [ -z "$title" ] || [ -z "$key_content" ]; then
        print_error "Usage: $0 add <username> <title> <key_content>"
        print_info "Example: $0 add johndoe 'My Laptop' \"\$(cat ~/.ssh/id_ed25519.pub)\""
        exit 1
    fi

    print_info "Adding SSH key '$title' for user: $username"

    # Pass key content via environment variable.
    # Note: We use a heredoc for the Ruby script.
    if docker compose exec -T \
        -e USERNAME="$username" \
        -e TITLE="$title" \
        -e KEY_CONTENT="$key_content" \
        git-server gitlab-rails runner << 'EOF'; then
user = User.find_by(username: ENV['USERNAME'])
if user
  key_content = ENV['KEY_CONTENT'].strip
  key = user.keys.new(title: ENV['TITLE'], key: key_content)
  if key.save
    puts "SSH key added successfully!"
  else
    puts "Error: #{key.errors.full_messages.join(', ')}"
    exit 1
  end
else
  puts "Error: User not found"
  exit 1
end
EOF
        print_info "✅ SSH key added successfully!"
    else
        print_error "Failed to add SSH key"
        exit 1
    fi
}

# Delete an SSH key for a user
delete_key() {
    local username=$1
    local key_id=$2

    if [ -z "$username" ] || [ -z "$key_id" ]; then
        print_error "Usage: $0 delete <username> <key_id>"
        exit 1
    fi

    if [[ ! $key_id =~ ^[0-9]+$ ]]; then
        print_error "Error: Key ID must be a number"
        exit 1
    fi

    print_warn "Deleting SSH key ID $key_id for user: $username"
    docker compose exec -T \
        -e USERNAME="$username" \
        -e KEY_ID="$key_id" \
        git-server gitlab-rails runner << 'EOF'
user = User.find_by(username: ENV['USERNAME'])
if user
  key = user.keys.find_by(id: ENV['KEY_ID'].to_i)
  if key
    key.destroy
    puts "SSH key deleted successfully!"
  else
    puts "Error: Key ID #{ENV['KEY_ID']} not found for user #{ENV['USERNAME']}"
    exit 1
  end
else
  puts "Error: User not found"
  exit 1
end
EOF
}

# Show help
show_help() {
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  list <username>                      List all SSH keys for a user"
    echo "  add <username> <title> <key_content> Add a new SSH key for a user"
    echo "  delete <username> <key_id>           Delete an SSH key for a user"
    echo "  help                                 Show this help message"
    echo ""
}

# Main execution
case "$1" in
    list)
        check_gitlab_running
        list_keys "$2"
        ;;
    add)
        check_gitlab_running
        add_key "$2" "$3" "$4"
        ;;
    delete)
        check_gitlab_running
        delete_key "$2" "$3"
        ;;
    help | *)
        show_help
        ;;
esac
