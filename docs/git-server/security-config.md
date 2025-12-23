# GitLab Security Configuration Guide

**Component**: Git Server (GitLab CE)  
**Focus**: Security and Access Control  
**Last Updated**: 2025-12-22

## Overview

This guide covers security best practices and configuration for the AutoGit Git Server. Proper security configuration is critical for protecting your code and infrastructure.

## Security Checklist

### Initial Setup Security
- [x] Change default admin password immediately
- [x] Disable user signup for private installations
- [x] Configure strong password policies
- [x] Enable rate limiting to prevent brute force attacks
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Configure firewall rules
- [ ] Set up regular backups

### User Security
- [x] Enforce minimum password length (12+ characters)
- [x] Require password complexity
- [ ] Enable 2FA for admin accounts
- [ ] Consider requiring 2FA for all users
- [ ] Regular user access audits
- [ ] Remove inactive users

### Network Security
- [x] Use Docker networks for service isolation
- [ ] Configure reverse proxy (nginx/traefik)
- [ ] Enable HTTPS/SSL
- [ ] Restrict admin access by IP (optional)
- [ ] Configure CORS policies
- [ ] Enable audit logging

## Password Security

### Strong Password Policy

Configure in `services/git-server/config/gitlab.rb.template`:

```ruby
## Password Requirements
gitlab_rails['gitlab_minimum_password_length'] = 12
gitlab_rails['password_authentication_enabled_for_web'] = true
gitlab_rails['password_authentication_enabled_for_git'] = true

## Password complexity (requires additional configuration)
# Enforce at least one uppercase, lowercase, number, and symbol
# This is handled by GitLab's built-in password validator
```

### Password Best Practices

1. **Minimum Length**: Set to at least 12 characters
2. **Complexity**: Require mix of character types
3. **No Common Passwords**: GitLab blocks common passwords
4. **Regular Changes**: Consider password expiration policies
5. **No Reuse**: Prevent password reuse (configure separately)

## Rate Limiting

### Brute Force Protection

Default configuration in `gitlab.rb.template`:

```ruby
## Rate Limiting (protects against brute force attacks)
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => [],
  'maxretry' => 10,      # Max failed attempts
  'findtime' => 60,      # Within 60 seconds  
  'bantime' => 3600      # Ban for 1 hour
}
```

### Custom Rate Limiting

Add trusted IPs to whitelist:
```ruby
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => ['192.168.1.0/24', '10.0.0.0/8'],
  'maxretry' => 10,
  'findtime' => 60,
  'bantime' => 3600
}
```

For stricter limits:
```ruby
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => [],
  'maxretry' => 5,       # Reduced attempts
  'findtime' => 60,
  'bantime' => 7200      # Longer ban (2 hours)
}
```

## Session Security

### Session Configuration

```ruby
## Session Settings
gitlab_rails['session_expire_delay'] = 10080  # 7 days in minutes

## For more secure environments, use shorter timeout
gitlab_rails['session_expire_delay'] = 480  # 8 hours
```

### Session Best Practices

1. **Timeout**: Set appropriate session timeout
2. **Remember Me**: Consider disabling for sensitive environments
3. **Active Sessions**: Users should review and revoke as needed
4. **Session Revocation**: Admins can force logout all users

## Two-Factor Authentication

### Enabling 2FA

**Individual Users**:
Users can enable 2FA from User Settings → Account

**Require 2FA for All Users**:
```ruby
gitlab_rails['two_factor_authentication'] = {
  'enabled' => true,
  'grace_period_in_hours' => 48  # Time to set up 2FA
}
```

### 2FA Best Practices

1. **Admin Accounts**: Always enable 2FA for admins
2. **Grace Period**: Give users time to set up
3. **Recovery Codes**: Ensure users save recovery codes
4. **Backup Methods**: Support multiple 2FA methods
5. **Lost Access**: Have recovery process for admins

## Network Security

### Docker Network Isolation

The git-server uses a dedicated Docker network:

```yaml
networks:
  autogit-network:
    driver: bridge
```

Only services on this network can communicate directly.

### Firewall Configuration

**Using UFW (Ubuntu)**:
```bash
# Allow only necessary ports
sudo ufw allow 2222/tcp  # SSH
sudo ufw allow 3000/tcp  # HTTP
sudo ufw allow 3443/tcp  # HTTPS

# Restrict admin access (optional)
sudo ufw allow from 192.168.1.0/24 to any port 3000
```

**Using iptables**:
```bash
# Allow GitLab ports
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
iptables -A INPUT -p tcp --dport 3443 -j ACCEPT
```

## HTTPS/SSL Configuration

### Using Let's Encrypt

Update `gitlab.rb`:
```ruby
external_url 'https://gitlab.yourdomain.com'

letsencrypt['enable'] = true
letsencrypt['contact_emails'] = ['admin@yourdomain.com']
letsencrypt['auto_renew'] = true
```

### Using Custom Certificates

```ruby
external_url 'https://gitlab.yourdomain.com'

nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.key"
```

Mount certificates via volume:
```yaml
volumes:
  - ./ssl:/etc/gitlab/ssl:ro
```

## Access Control

### Disable User Signup

For private installations:
```ruby
gitlab_rails['gitlab_signup_enabled'] = false
```

Or via Admin UI:
1. Admin Area → Settings → General
2. Sign-up restrictions → Disable sign-up

### IP Restrictions (Optional)

Restrict admin access by IP:
```ruby
gitlab_rails['admin_allowed_ips'] = ['192.168.1.0/24', '10.0.0.0/8']
```

## Audit Logging

### Enable Audit Events

Audit events are enabled by default. View them:
1. Admin Area → Monitoring → Audit Events

### Log Locations

Important log files:
```
/var/log/gitlab/gitlab-rails/production.log
/var/log/gitlab/gitlab-rails/api_json.log
/var/log/gitlab/nginx/gitlab_access.log
/var/log/gitlab/nginx/gitlab_error.log
```

View logs:
```bash
docker compose exec git-server tail -f /var/log/gitlab/gitlab-rails/production.log
```

## Vulnerability Management

### Regular Updates

Keep GitLab updated:
```bash
# Check current version
docker compose exec git-server gitlab-rake gitlab:env:info

# Update to new version
# 1. Update Dockerfile with new version
# 2. Rebuild and restart
docker compose up -d --build git-server
```

### Security Scanning

GitLab includes security features:
- Dependency scanning
- Container scanning
- Secret detection
- License compliance

Configure in `.gitlab-ci.yml` for projects.

## Backup and Recovery

### Automated Backups

Configure backup schedule:
```ruby
gitlab_rails['backup_keep_time'] = 604800  # 7 days
```

Create backup:
```bash
docker compose exec git-server gitlab-backup create
```

### Backup Security

1. **Encryption**: Encrypt backup files
2. **Off-site**: Store backups off-site
3. **Regular Testing**: Test restore procedure
4. **Access Control**: Restrict backup file access

## Monitoring and Alerting

### Health Checks

Built-in health endpoints:
```bash
curl http://localhost:3000/-/health
curl http://localhost:3000/-/readiness
curl http://localhost:3000/-/liveness
```

### Failed Login Monitoring

Monitor failed logins:
```bash
docker compose exec git-server grep "Failed Login" \
  /var/log/gitlab/gitlab-rails/production.log
```

### Prometheus Metrics

GitLab exports Prometheus metrics on port 9090 (internal).

## Incident Response

### Account Compromise

If an account is compromised:

1. **Block the account immediately**:
   ```bash
   ./services/git-server/scripts/manage-users.sh block <username>
   ```

2. **Revoke all sessions**:
   - Admin Area → Users → [Select User] → Impersonate/Edit
   - Force logout

3. **Reset password**:
   ```bash
   docker compose exec git-server gitlab-rake "gitlab:password:reset[username]"
   ```

4. **Review access logs**:
   ```bash
   docker compose exec git-server grep "username" \
     /var/log/gitlab/gitlab-rails/audit_json.log
   ```

5. **Check for unauthorized changes**:
   - Review recent commits
   - Check project access changes
   - Review API token usage

### Data Breach Response

1. **Isolate the system**
2. **Assess the scope**
3. **Notify affected parties**
4. **Preserve evidence**
5. **Restore from clean backup**
6. **Implement additional controls**

## Compliance

### GDPR Compliance

- Right to access: Users can export their data
- Right to erasure: Admin can delete user accounts
- Data portability: Git repositories are portable
- Audit logging: Full audit trail available

### SOC 2 / ISO 27001

Relevant controls:
- Access control (AC)
- Audit and accountability (AU)
- Identification and authentication (IA)
- System and communications protection (SC)

## Security Hardening

### Additional Hardening Steps

1. **Disable unnecessary services**:
   ```ruby
   registry['enable'] = false
   pages['enable'] = false
   mattermost['enable'] = false
   ```

2. **Limit rate of API requests**:
   ```ruby
   gitlab_rails['rate_limit_requests_per_period'] = 1000
   gitlab_rails['rate_limit_period'] = 60
   ```

3. **Enable security headers**:
   ```ruby
   nginx['proxy_set_headers'] = {
     "X-Frame-Options" => "DENY",
     "X-Content-Type-Options" => "nosniff",
     "X-XSS-Protection" => "1; mode=block"
   }
   ```

4. **Restrict admin interface**:
   Only allow admin access from trusted networks

## Security Resources

### GitLab Security Resources
- [GitLab Security Docs](https://docs.gitlab.com/ce/security/)
- [Securing your GitLab instance](https://docs.gitlab.com/ce/security/hardening.html)
- [GitLab Security Best Practices](https://docs.gitlab.com/ce/security/best_practices.html)

### External Resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

## Regular Security Tasks

### Daily
- [ ] Monitor failed login attempts
- [ ] Review audit logs for suspicious activity
- [ ] Check system health

### Weekly
- [ ] Review user accounts and access
- [ ] Check for GitLab security updates
- [ ] Test backup restoration

### Monthly
- [ ] Full security audit
- [ ] Password policy review
- [ ] Access control review
- [ ] Update security documentation

### Quarterly
- [ ] Penetration testing
- [ ] Disaster recovery drill
- [ ] Security training for users
- [ ] Policy and procedure review

---

**Security is an ongoing process, not a one-time configuration. Regular reviews and updates are essential.**
