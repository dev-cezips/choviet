# Chợ Việt - Vietnamese Community Platform

Korean-Vietnamese community marketplace and forum application built with Rails 8.

## System Requirements

* Ruby 3.4.4
* SQLite3
* Node.js & Yarn
* Docker (for deployment with Kamal)

## Development Setup

```bash
# Install dependencies
bundle install
yarn install

# Setup database
bin/rails db:create db:migrate db:seed

# Start development server
bin/dev
```

## Deployment

This application is deployed using Kamal to AWS Lightsail.

### Deploy to production
```bash
bin/kamal deploy
```

### View logs
```bash
bin/kamal app logs
```

## Production Monitoring & Troubleshooting

### 1. DNS Verification
Check that both domains point to the correct server:
```bash
# Check apex domain
dig @1.1.1.1 +short A choviet.chat

# Check www subdomain  
dig @1.1.1.1 +short A www.choviet.chat

# Both should return: 3.34.133.227
```

### 2. SSL Certificate Verification
Verify SSL certificate is valid and includes correct domains:
```bash
# Check certificate for apex domain
openssl s_client -connect choviet.chat:443 -servername choviet.chat </dev/null 2>/dev/null | \
  openssl x509 -noout -issuer -subject -dates -ext subjectAltName

# Check certificate for www subdomain
openssl s_client -connect www.choviet.chat:443 -servername www.choviet.chat </dev/null 2>/dev/null | \
  openssl x509 -noout -issuer -subject -dates -ext subjectAltName
```

### 3. Health Check
Verify the application is responding correctly:
```bash
# Check apex domain health
curl -I https://choviet.chat/up

# Check www subdomain (should redirect to apex)
curl -I https://www.choviet.chat/up
```

### 4. Proxy Logs
Check Kamal proxy logs for any TLS or connection errors:
```bash
# View recent proxy logs
bin/kamal proxy logs

# Follow proxy logs in real-time
bin/kamal proxy logs -f
```

### 5. Application Logs
Check application logs for errors:
```bash
# View recent application logs
bin/kamal app logs

# Follow application logs in real-time
bin/kamal app logs -f
```

### Post-Deployment Checklist

1. **DNS Resolution** - Verify both domains resolve to server IP
2. **SSL Certificate** - Confirm certificate is valid for both domains
3. **Health Check** - Ensure `/up` returns 200 OK
4. **Redirects** - Verify www redirects to apex domain
5. **Logs** - Check for any errors in proxy or app logs

### Common Issues

**Issue**: SSL certificate error for www subdomain
- **Solution**: The SSL certificate only covers the apex domain. www requests are redirected at the application level.

**Issue**: Deploy fails with "target failed to become healthy"
- **Solution**: Check that the database migrations have run and all services are started:
  ```bash
  bin/kamal app exec 'bin/rails db:migrate'
  ```

**Issue**: Connection refused errors
- **Solution**: Ensure the server is accessible and security groups allow HTTP/HTTPS traffic:
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 22 (SSH)
