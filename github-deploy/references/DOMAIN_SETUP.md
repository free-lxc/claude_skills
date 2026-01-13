# Domain and DNS Configuration Guide

Complete guide for configuring custom domains with GitHub Pages.

## Subdomain vs Apex Domain

### Subdomain (www, blog, etc.)

Example: `www.example.com`, `blog.example.com`

**DNS Configuration:**
- Type: `CNAME`
- Name: `www` or subdomain name
- Value: `[username].github.io` or `[org].github.io`

### Apex Domain (root domain)

Example: `example.com`

**DNS Configuration:**
- Type: `A` (4 records required)
- Name: `@` or leave empty
- Values:
  - `185.199.108.153`
  - `185.199.109.153`
  - `185.199.110.153`
  - `185.199.111.153`

---

## Common DNS Providers

### Cloudflare

**For subdomain:**
```
Type: CNAME
Name: www
Target: username.github.io
Proxy status: DNS only (gray cloud)
TTL: Auto
```

**For apex domain:**
```
Type: A
Name: @
IPv4 address: 185.199.108.153
Proxy status: DNS only (gray cloud)
```
*Repeat for all 4 IP addresses*

⚠️ **Important:** Disable Cloudflare proxy (orange cloud) for GitHub Pages to work correctly.

### Namecheap

**For subdomain:**
```
Type: CNAME Record
Host: www
Value: username.github.io
TTL: Automatic
```

**For apex domain:**
```
Type: A Record
Host: @
Value: 185.199.108.153
TTL: Automatic
```
*Repeat for all 4 IP addresses*

### GoDaddy

**For subdomain:**
```
Type: CNAME
Name: www
Value: username.github.io
TTL: 1 hour
```

**For apex domain:**
```
Type: A
Name: @
Value: 185.199.108.153
TTL: 1 hour
```
*Repeat for all 4 IP addresses*

### Google Domains

**For subdomain:**
```
Type: CNAME
Name: www
TTL: 3600
Data: username.github.io
```

**For apex domain:**
```
Type: A
Name: @
TTL: 3600
Data: 185.199.108.153
```
*Repeat for all 4 IP addresses*

---

## GitHub Repository Configuration

### Step 1: Create CNAME File

Create a file named `CNAME` (no extension) in your repository root:

```
example.com
```

Or for subdomain:
```
www.example.com
```

**Location options:**
- Repository root (recommended)
- Inside `/docs` folder if publishing from docs

### Step 2: Configure in GitHub Settings

1. Go to repository **Settings**
2. Navigate to **Pages** (sidebar)
3. Under **Custom domain**, enter your domain
4. Click **Save**
5. Wait for DNS check to pass
6. Click **Enforce HTTPS** (recommended)

### Step 3: Verify DNS Propagation

```bash
# Check CNAME record
dig www.example.com CNAME

# Check A records
dig example.com A

# Check with specific DNS server
dig example.com A @8.8.8.8
```

Or use online tools:
- [DNSChecker](https://dnschecker.org/)
- [WhatsMyDNS](https://www.whatsmydns.net/)

---

## HTTPS Configuration

### Automatic Certificate

GitHub Pages automatically provisions Let's Encrypt certificates for custom domains.

**After DNS propagates:**
1. Wait for "Custom domain" check to pass in GitHub
2. **Enforce HTTPS** button will become available
3. Click to enable HTTPS

**Certificate provisioning time:** Usually instant, can take up to 24 hours

### Certificate Issues

**"Certificate not yet valid" error:**
- Wait 5-10 minutes for certificate generation
- Check DNS is correctly configured
- Ensure CNAME file matches domain

**"Certificate has expired" error:**
- Certificates auto-renew every ~90 days
- If expired, check GitHub Status for outages
- Manually remove and re-add domain

---

## www to non-www Redirect

### Option 1: CNAME Flattening

Some DNS providers support CNAME flattening for apex domains:
- Cloudflare: CNAME Flattening
- DNSimple: ALIAS records

### Option 2: Both Records

Add both CNAME and A records:

```
# Subdomain
Type: CNAME
Name: www
Value: username.github.io

# Apex
Type: A
Name: @
Values: 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153
```

Then configure redirect in GitHub Pages settings or use JavaScript:

```javascript
// In your site's JavaScript
if (window.location.hostname === 'example.com') {
  window.location.href = 'https://www.example.com' + window.location.pathname;
}
```

### Option 3: Cloudflare Page Rules

If using Cloudflare:

1. Create Page Rule
2. Pattern: `example.com/*`
3. Setting: Forwarding URL
4. Status: 301 - Permanent Redirect
5. Destination: `https://www.example.com/$1`

---

## Troubleshooting

### DNS Check Failing

**Symptoms:** GitHub shows "DNS check failed" or "Incorrect DNS configuration"

**Solutions:**
1. Verify DNS records match exactly
2. Check for typos in CNAME file
3. Wait for DNS propagation (can take 24-48 hours)
4. Ensure no conflicting records

### Site Not Accessible

**Symptoms:** Browser shows "Server not found" or similar

**Solutions:**
1. Check DNS propagation with `dig` or online tools
2. Verify CNAME file exists in repository
3. Confirm GitHub Pages is deploying
4. Check browser is not using cached DNS

### HTTPS Not Working

**Symptoms:** "Enforce HTTPS" button disabled or certificate errors

**Solutions:**
1. Wait longer for DNS to propagate
2. Ensure DNS check passes first
3. Check CNAME file matches domain exactly
4. Remove and re-add domain in GitHub settings

### Subdirectory Deployment with Custom Domain

When deploying to `username.github.io/repository-name` with custom domain:

1. CNAME file in repository root
2. Framework config must include base path:
   ```javascript
   // Vite
   base: '/',
   ```
3. The custom domain replaces the entire GitHub.io URL

---

## Multiple Repositories, One Domain

### Subdomain Approach

Assign different subdomains to each repo:

```
blog.example.com → blog repo
docs.example.com → docs repo
app.example.com → app repo
```

Each repo has its own CNAME file.

### Path Approach

Use a single repo with redirects or server-side routing:

```
example.com/blog → blog content
example.com/docs → docs content
```

Requires framework-level routing or rewrite rules.

---

## DNS Record Reference

### GitHub Pages IP Addresses

Always use these four A records for apex domains:

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

### GitHub Pages CNAME Target

Format: `[username].github.io` or `[organization].github.io`

Examples:
- `johnsmith.github.io`
- `acme-corp.github.io`

---

## TTL Recommendations

| Record Type | Recommended TTL |
|-------------|-----------------|
| A Records | 3600 (1 hour) |
| CNAME | 3600 (1 hour) |
| During setup | 300 (5 minutes) |
| After confirmed | 86400 (1 day) |

Use lower TTL during initial setup for faster changes to propagate.

---

## Security Considerations

### DNSSEC

GitHub Pages does not currently support DNSSEC.

**If your domain uses DNSSEC:**
- Pause DNSSEC validation during setup
- Resume after domain is verified
- Or use subdomain without DNSSEC

### CAA Records

Optionally restrict which CAs can issue certificates:

```
example.com. CAA 0 issue "letsencrypt.org"
```

GitHub Pages uses Let's Encrypt by default.

---

## Checklist

- [ ] DNS records configured correctly
- [ ] CNAME file created in repository
- [ ] Domain added in GitHub Pages settings
- [ ] DNS check passes in GitHub
- [ ] HTTPS enforced
- [ ] Site accessible via custom domain
- [ ] www redirect configured (if needed)
- [ ] Test with `dig` commands
- [ ] Monitor for SSL certificate expiry
