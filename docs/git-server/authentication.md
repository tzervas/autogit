# GitLab Authentication and User Management

**Component**: Git Server (GitLab CE) - Authentication
**Version**: 16.11.0-ce.0
**Status**: Production Ready
**Last Updated**: 2025-12-22

## Overview

This document describes the authentication setup and user management for the AutoGit Git Server. GitLab CE provides comprehensive authentication and user management capabilities out of the box.

## Authentication Features

### Built-in Authentication
- Username/password authentication
- SSH key authentication
- Personal access tokens
- Session management with configurable timeout
- Rate limiting to prevent brute force attacks
- Password complexity requirements

### Optional Authentication Methods
- LDAP/Active Directory integration
- OAuth2 providers (GitHub, Google, etc.)
- SAML SSO
- Two-Factor Authentication (2FA)

## Initial Setup

### 1. Configure Admin User

The root admin user password is set via the `GITLAB_ROOT_PASSWORD` environment variable.

**Using .env file** (recommended):
```bash
# Copy the example env file
cp services/git-server/.env.example services/git-server/.env

# Edit .env and set a secure password
vi services/git-server/.env
# Set: GITLAB_ROOT_PASSWORD=YourSecurePassword123!
```

**Using setup script**:
```bash
# After GitLab is running, use the setup script
export GITLAB_ROOT_PASSWORD='YourSecurePassword123!'
./services/git-server/scripts/setup-admin.sh
```

### 2. First Login

1. Start GitLab: `docker compose up -d git-server`
2. Wait 3-5 minutes for initialization
3. Access: http://localhost:3000
4. Login with:
   - Username: `root`
   - Password: (value from `GITLAB_ROOT_PASSWORD`)

### 3. Configure Authentication Settings

After first login:

1. Go to **Admin Area** → **Settings** → **General**
2. Expand **Sign-up restrictions**:
   - Disable sign-up to prevent unauthorized registrations
   - Set domain restrictions if needed
   - Configure email confirmation requirements

3. Expand **Sign-in restrictions**:
   - Set session duration
   - Enable/disable password authentication
   - Configure failed login attempts handling

4. Expand **Account and limit**:
   - Set user limits
   - Configure project/group creation restrictions

## Password Policies

### Default Requirements
- Minimum length: 12 characters (configurable)
- Must include: uppercase, lowercase, number, and symbol
- Cannot be a common password
- Cannot match username or email

### Configuring Password Policy

Edit `services/git-server/config/gitlab.rb.template`:

```ruby
## Password Requirements
gitlab_rails['gitlab_minimum_password_length'] = 12
gitlab_rails['password_authentication_enabled_for_web'] = true
gitlab_rails['password_authentication_enabled_for_git'] = true
```

Apply changes:
```bash
docker compose restart git-server
```

## User Management

### Creating Users

**Option 1: Using the Web UI** (recommended for few users)
1. Login as admin
2. Go to **Admin Area** → **Users** → **New User**
3. Fill in user details
4. Set password or send reset link
5. Assign admin role if needed

**Option 2: Using the management script** (recommended for automation)
```bash
# Create a regular user
./services/git-server/scripts/manage-users.sh create \
  johndoe \
  john@example.com \
  SecurePassword123! \
  "John Doe" \
  false

# Create an admin user
./services/git-server/scripts/manage-users.sh create \
  alice \
  alice@example.com \
  AdminPass456! \
  "Alice Admin" \
  true
```

**Option 3: Using GitLab API**
```bash
curl --request POST \
  --header "PRIVATE-TOKEN: your-access-token" \
  --data "email=user@example.com" \
  --data "password=SecurePassword123!" \
  --data "username=newuser" \
  --data "name=New User" \
  "http://localhost:3000/api/v4/users"
```

### Listing Users
```bash
# Using management script
./services/git-server/scripts/manage-users.sh list

# Using GitLab API
curl --header "PRIVATE-TOKEN: your-access-token" \
  "http://localhost:3000/api/v4/users"
```

### Blocking/Unblocking Users
```bash
# Block a user (prevents login)
./services/git-server/scripts/manage-users.sh block johndoe

# Unblock a user
./services/git-server/scripts/manage-users.sh unblock johndoe
```

### Deleting Users
```bash
# Delete a user (cannot be undone)
./services/git-server/scripts/manage-users.sh delete johndoe
```

## Session Management

### Configuration

Sessions are configured in `gitlab.rb`:

```ruby
## Session Settings
gitlab_rails['session_expire_delay'] = 10080  # 7 days in minutes
```

### Session Features
- Automatic logout after inactivity
- "Remember me" option on login
- Active session viewing and termination
- Device tracking

### Managing Sessions

**View active sessions**:
1. Login to GitLab
2. Go to **User Settings** → **Active Sessions**
3. View all active sessions with location and device info
4. Revoke sessions as needed

## Rate Limiting

Protection against brute force attacks is configured by default:

```ruby
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => [],
  'maxretry' => 10,      # Max failed attempts
  'findtime' => 60,      # Within 60 seconds
  'bantime' => 3600      # Ban for 1 hour
}
```

### Custom Rate Limiting

To add IP addresses to whitelist (skip rate limiting):
```ruby
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => ['192.168.1.100', '10.0.0.0/8'],
  'maxretry' => 10,
  'findtime' => 60,
  'bantime' => 3600
}
```

## Two-Factor Authentication (2FA)

### Enabling 2FA

**For individual users**:
1. Login to GitLab
2. Go to **User Settings** → **Account**
3. Click **Enable Two-Factor Authentication**
4. Scan QR code with authenticator app
5. Enter verification code

**Requiring 2FA for all users** (optional):

Edit `gitlab.rb.template`:
```ruby
gitlab_rails['two_factor_authentication'] = {
  'enabled' => true,
  'grace_period_in_hours' => 48
}
```

### 2FA Recovery

If a user loses 2FA access:
1. Admin logs into GitLab
2. Go to **Admin Area** → **Users**
3. Find the user and click **Edit**
4. Click **Disable Two-Factor Authentication**
5. User can re-enable with new device

## LDAP/Active Directory Integration

For enterprise environments, integrate with existing directory services.

### Configuration

Edit `services/git-server/config/gitlab.rb.template`:

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  label: 'Company LDAP'
  host: 'ldap.company.com'
  port: 389
  uid: 'sAMAccountName'
  bind_dn: 'CN=gitlab,CN=Users,DC=company,DC=com'
  password: 'bind_user_password'
  encryption: 'plain'  # or 'simple_tls' or 'start_tls'
  verify_certificates: true
  active_directory: true
  allow_username_or_email_login: true
  block_auto_created_users: false
  base: 'DC=company,DC=com'
  user_filter: '(memberOf=CN=GitLab Users,OU=Groups,DC=company,DC=com)'
EOS
```

### LDAP Features
- Automatic user provisioning
- Group synchronization
- Password authentication via LDAP
- Periodic user sync

### Testing LDAP Configuration
```bash
docker compose exec git-server gitlab-rake gitlab:ldap:check
```

## OAuth2 Integration

Integrate with external OAuth2 providers for SSO.

### Supported Providers
- GitHub
- Google
- Azure AD
- Auth0
- Custom OAuth2 providers

### GitHub OAuth Configuration

1. Create OAuth App on GitHub:
   - Go to GitHub Settings → Developer settings → OAuth Apps
   - Create new OAuth App
   - Authorization callback URL: `http://localhost:3000/users/auth/github/callback`

2. Configure in `gitlab.rb.template`:
```ruby
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['github']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_providers'] = [
  {
    "name" => "github",
    "app_id" => "YOUR_GITHUB_CLIENT_ID",
    "app_secret" => "YOUR_GITHUB_CLIENT_SECRET",
    "args" => { "scope" => "user:email" }
  }
]
```

## Security Best Practices

### Password Security
- [x] Use strong passwords (min 12 characters)
- [x] Enable password complexity requirements
- [x] Configure password expiration (optional)
- [x] Prevent password reuse

### Account Security
- [x] Disable user signup for private installations
- [x] Enable 2FA for admin accounts (recommended)
- [x] Require 2FA for all users (optional)
- [x] Regular audit of active users
- [x] Remove unused accounts

### Session Security
- [x] Set appropriate session timeout
- [x] Enable rate limiting
- [x] Monitor failed login attempts
- [x] Review active sessions regularly

### Network Security
- [x] Use HTTPS in production
- [x] Restrict admin access by IP (optional)
- [x] Enable audit logging
- [x] Regular security updates

## Troubleshooting

### Cannot Login
1. Verify GitLab is running: `docker compose ps git-server`
2. Check logs: `docker compose logs git-server`
3. Verify password is set: `echo $GITLAB_ROOT_PASSWORD`
4. Try password reset: `./services/git-server/scripts/setup-admin.sh`

### Account Locked
- Wait for ban period to expire (default 1 hour)
- Or whitelist IP in rate limiting config
- Admin can unlock from Admin Area

### 2FA Issues
- Admin can disable 2FA for user from Admin Area
- User re-enables with new device
- Keep recovery codes safe

### LDAP Not Working
1. Test connection: `docker compose exec git-server gitlab-rake gitlab:ldap:check`
2. Verify credentials and DN paths
3. Check network connectivity to LDAP server
4. Review logs: `docker compose exec git-server tail -f /var/log/gitlab/gitlab-rails/production.log`

## API Access

### Personal Access Tokens

Users can create personal access tokens for API/Git access:

1. Login to GitLab
2. Go to **User Settings** → **Access Tokens**
3. Create token with required scopes:
   - `api` - Full API access
   - `read_api` - Read-only API access
   - `read_repository` - Read repositories
   - `write_repository` - Write repositories

### Using Access Tokens
```bash
# API request with token
curl --header "PRIVATE-TOKEN: your-token" \
  "http://localhost:3000/api/v4/user"

# Git clone with token
git clone http://oauth2:your-token@localhost:3000/username/repo.git
```

## References

- [GitLab Authentication Documentation](https://docs.gitlab.com/ce/topics/authentication/)
- [GitLab User Management](https://docs.gitlab.com/ce/user/admin_area/user_management.html)
- [GitLab LDAP Integration](https://docs.gitlab.com/ce/administration/auth/ldap/)
- [GitLab OAuth2 Providers](https://docs.gitlab.com/ce/integration/oauth_provider.html)
- [GitLab Security](https://docs.gitlab.com/ce/security/)

---

**Next Steps**: Configure SSH Access (Subtask 3)
