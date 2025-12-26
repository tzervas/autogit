#!/bin/bash
# User Management Script for GitLab
# Provides commands to create, list, and manage GitLab users

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
    if ! docker compose ps git-server | grep -q "Up"; then
        print_error "GitLab container is not running"
        exit 1
    fi
}

# List all users
list_users() {
    print_info "Listing all GitLab users:"
    docker compose exec git-server gitlab-rails runner 'User.all.each { |u| puts "ID: #{u.id}, Username: #{u.username}, Email: #{u.email}, Admin: #{u.admin}" }'
}

# Create a new user
create_user() {
    local username=$1
    local email=$2
    local password=$3
    local name=$4
    local is_admin=$5

    if [ -z "$username" ] || [ -z "$email" ] || [ -z "$password" ]; then
        print_error "Usage: $0 create <username> <email> <password> [name] [admin]"
        exit 1
    fi

    if [ -z "$name" ]; then
        name="$username"
    fi

    if [ -z "$is_admin" ]; then
        is_admin="false"
    fi

    print_info "Creating user: $username ($email)"

    if docker compose exec -T git-server gitlab-rails runner << EOF; then
user = User.new(
  username: '${username}',
  email: '${email}',
  name: '${name}',
  password: '${password}',
  password_confirmation: '${password}',
  admin: ${is_admin}
)
user.skip_confirmation!
if user.save
  puts "User created successfully!"
else
  puts "Error: #{user.errors.full_messages.join(', ')}"
  exit 1
end
EOF
        print_info "✅ User created successfully!"
    else
        print_error "Failed to create user"
        exit 1
    fi
}

# Delete a user
delete_user() {
    local username=$1

    if [ -z "$username" ]; then
        print_error "Usage: $0 delete <username>"
        exit 1
    fi

    print_warn "Deleting user: $username"
    docker compose exec -T git-server gitlab-rails runner << EOF
user = User.find_by(username: '${username}')
if user
  user.delete_self_and_dependent_artifacts!
  puts "User deleted successfully!"
else
  puts "User not found: ${username}"
  exit 1
end
EOF
}

# Block a user
block_user() {
    local username=$1

    if [ -z "$username" ]; then
        print_error "Usage: $0 block <username>"
        exit 1
    fi

    print_info "Blocking user: $username"
    docker compose exec -T git-server gitlab-rails runner << EOF
user = User.find_by(username: '${username}')
if user
  user.block!
  puts "User blocked successfully!"
else
  puts "User not found: ${username}"
  exit 1
end
EOF
}

# Unblock a user
unblock_user() {
    local username=$1

    if [ -z "$username" ]; then
        print_error "Usage: $0 unblock <username>"
        exit 1
    fi

    print_info "Unblocking user: $username"
    docker compose exec -T git-server gitlab-rails runner << EOF
user = User.find_by(username: '${username}')
if user
  user.unblock!
  puts "User unblocked successfully!"
else
  puts "User not found: ${username}"
  exit 1
end
EOF
}

# Show help
show_help() {
    cat << EOF
GitLab User Management Script

Usage: $0 <command> [arguments]

Commands:
  list                                    - List all users
  create <user> <email> <pass> [name] [admin] - Create a new user
  delete <username>                       - Delete a user
  block <username>                        - Block a user
  unblock <username>                      - Unblock a user
  help                                    - Show this help message

Examples:
  $0 list
  $0 create john john@example.com SecurePass123 "John Doe" false
  $0 create alice alice@example.com AdminPass456 "Alice Admin" true
  $0 block john
  $0 unblock john
  $0 delete john

Notes:
  - Passwords must be at least 12 characters long
  - Use 'true' for admin users, 'false' for regular users
  - Deleted users cannot be recovered
EOF
}

# Main script logic
check_gitlab_running

case "$1" in
    list)
        list_users
        ;;
    create)
        create_user "$2" "$3" "$4" "$5" "$6"
        ;;
    delete)
        delete_user "$2"
        ;;
    block)
        block_user "$2"
        ;;
    unblock)
        unblock_user "$2"
        ;;
    help | --help | -h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
