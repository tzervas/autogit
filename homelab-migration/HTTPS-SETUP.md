# GitLab HTTPS Setup with Domain Configuration
# For vectorweight.com domain with LAN-only access

## 📋 Prerequisites
- Google Domains account for vectorweight.com
- Homelab server LAN IP (192.168.1.170)
- SSL certificates generated

## 🌐 DNS Configuration (Squarespace)

### Step 1: Access Squarespace DNS Settings
1. Log in to your Squarespace account
2. Go to **Home** → **Settings** → **Domains**
3. Select **vectorweight.com**
4. Click **DNS Settings** or **Advanced Settings**
5. Look for **DNS Records** or **Custom Records**

### Step 2: Add A Record for gitlab.vectorweight.com

In Squarespace's DNS interface:

1. Click **Add Record** or **+ Add Custom Record**
2. Select record type: **A**
3. Fill in the fields:
   ```
   Host: gitlab
   Value: 192.168.1.170
   TTL: 1 hour (or leave default)
   ```
4. Click **Save** or **Add**

### Step 3: Verify the Record

Squarespace should show your new record in the DNS records list. It should look like:
```
Type: A
Host: gitlab.vectorweight.com
Value: 192.168.1.170
TTL: 1 hour
```

### Alternative: If You Don't See DNS Options

Some Squarespace plans might not show DNS settings directly. In this case:

1. **Contact Squarespace Support:** Ask them to add the A record for you
2. **Transfer DNS:** Consider transferring DNS management to a more flexible provider like:
   - Google Domains
   - Cloudflare
   - Namecheap
   - Or use the hosts file method below for testing

### Squarespace Interface Notes
- **Record Type:** Choose "A" from the dropdown
- **Host Field:** Enter "gitlab" (not the full domain)
- **Value/Points to:** Enter "192.168.1.170"
- **TTL:** Squarespace might call this "Time to Live" - set to 1 hour
- **Save:** Changes are usually applied immediately but may take time to propagate

### Step 4: DNS Propagation
- **Squarespace DNS:** Usually propagates within 1-24 hours
- **Check Status:** Use online DNS tools or the commands below

### Step 4: Local Testing (Before DNS Propagates)
For immediate testing, add to your local hosts file:
```bash
# On Linux/Mac
echo "192.168.1.170 gitlab.vectorweight.com" | sudo tee -a /etc/hosts

# On Windows (run as Administrator)
# Add to C:\Windows\System32\drivers\etc\hosts:
# 192.168.1.170 gitlab.vectorweight.com
```

### Step 5: DNS Propagation Notes
- **Time:** DNS changes can take 1-48 hours to propagate globally
- **Local Network:** Changes are usually immediate on your local network
- **Testing:** Use the hosts file method above for instant testing
- **Verification:** Use tools like `dig` or `nslookup` to check propagation

### Troubleshooting DNS Issues
If you can't find DNS settings or records aren't working:

**Squarespace-Specific Issues:**
1. **DNS Not Visible:** Some Squarespace plans hide advanced DNS. Contact Squarespace support to add the record.
2. **Record Not Saving:** Try different TTL values or contact Squarespace support.
3. **Propagation Delay:** Squarespace DNS can take up to 48 hours.

**General Solutions:**
1. **Contact Squarespace Support:** Ask them to add the A record for you
2. **Transfer DNS Management:** Consider transferring to a provider with full DNS control
3. **Use Hosts File:** For immediate testing, edit local hosts file as shown below

**If Squarespace Support is Needed:**
- Tell them: "I need to add an A record pointing gitlab.vectorweight.com to 192.168.1.170"
- Reference: This is for internal LAN access to a GitLab server

## 🔒 SSL Certificate Trust (LAN Access)

### Option 1: Browser Trust (Quick)
1. Visit https://gitlab.vectorweight.com
2. Click "Advanced" → "Proceed to gitlab.vectorweight.com (unsafe)"
3. Add permanent exception

### Option 2: System Certificate Store (Recommended)
```bash
# On Linux clients
sudo cp data/gitlab/ssl/gitlab.vectorweight.com.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# On Windows clients
# Import data/gitlab/ssl/gitlab.vectorweight.com.crt into Trusted Root Certification Authorities
```

## 🚀 Deployment Steps

1. **Generate SSL Certificates:**
   ```bash
   cd ~/homelab-gitlab
   ./generate-ssl-cert.sh
   ```

2. **Deploy GitLab with HTTPS:**
   ```bash
   export GITHUB_PAT_MIRROR='your_github_token'
   export GITLAB_PAT_MIRROR='your_gitlab_token'
   ./setup-complete.sh
   ```

3. **Update Local DNS (Optional):**
   ```bash
   # Add to /etc/hosts for immediate testing
   echo "192.168.1.170 gitlab.vectorweight.com" | sudo tee -a /etc/hosts
   ```

## 🔍 Testing

```bash
# Test HTTPS access
curl -I https://gitlab.vectorweight.com

# Test repository access
git clone https://gitlab.vectorweight.com/mirrors/github-repo.git
```

## ⚠️ Security Notes

- **LAN Only:** This setup is for internal network access only
- **Self-Signed Certificates:** Appropriate for homelab, not production
- **Firewall:** Ensure ports 80, 443, 2222 are open on homelab server
- **DNS:** Records point to private IP, not exposed to internet

## 🔧 Troubleshooting

### Certificate Errors
```bash
# Regenerate certificates
rm -rf data/gitlab/ssl/
./generate-ssl-cert.sh
docker compose restart gitlab
```

### DNS Issues
```bash
# Check local DNS resolution
nslookup gitlab.vectorweight.com

# Check hosts file
cat /etc/hosts | grep vectorweight
```

### Port Issues
```bash
# Check if ports are open
sudo netstat -tlnp | grep -E ':(80|443|2222)'
```
