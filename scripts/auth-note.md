# Authentication Setup Guide

This document provides detailed instructions for setting up authentication for the MCP Todo Connector server.

## Authentication Methods

The MCP Todo Connector supports multiple authentication methods to secure access to your todo data:

### 1. No Authentication (Default)
- **Use Case**: Local development, trusted environments
- **Security Level**: None
- **Configuration**: No additional setup required

### 2. API Key Authentication
- **Use Case**: Simple authentication for single-user scenarios
- **Security Level**: Basic
- **Configuration**: Set `API_KEY` in environment variables

### 3. JWT Token Authentication
- **Use Case**: Multi-user applications, integration with existing auth systems
- **Security Level**: Medium to High
- **Configuration**: Requires JWT secret and token validation

### 4. OAuth 2.0 Integration
- **Use Case**: Enterprise applications, third-party integrations
- **Security Level**: High
- **Configuration**: Requires OAuth provider setup

## Quick Setup: API Key Authentication

This is the simplest authentication method to get started:

### Step 1: Generate API Key

```bash
# Generate a secure random API key (Linux/macOS)
openssl rand -hex 32

# Or use Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

```powershell
# Generate a secure random API key (Windows PowerShell)
[System.Web.Security.Membership]::GeneratePassword(64, 0)

# Or use .NET crypto
Add-Type -AssemblyName System.Security
[System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32) | ForEach-Object { $_.ToString("x2") } | Join-String
```

### Step 2: Configure Environment

Add the API key to your `.env` file:

```env
# API Key Authentication
API_KEY=your-generated-api-key-here
AUTH_METHOD=api_key
```

### Step 3: Test Authentication

```bash
# Test with curl (replace YOUR_API_KEY with your actual key)
curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:3000/mcp/tools

# Test with PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/mcp/tools" -Headers @{"Authorization"="Bearer YOUR_API_KEY"}
```

## Advanced Setup: JWT Authentication

For more sophisticated authentication needs:

### Step 1: Generate JWT Secret

```bash
# Generate JWT secret
openssl rand -base64 64
```

### Step 2: Configure JWT Settings

```env
# JWT Authentication
AUTH_METHOD=jwt
JWT_SECRET=your-jwt-secret-here
JWT_EXPIRATION=24h
JWT_ISSUER=mcp-todo-connector
```

### Step 3: Token Generation

Create a script to generate JWT tokens:

```javascript
// generate-token.js
const jwt = require('jsonwebtoken');

const payload = {
  userId: 'user123',
  username: 'john.doe',
  permissions: ['read', 'write', 'delete']
};

const token = jwt.sign(payload, process.env.JWT_SECRET, {
  expiresIn: process.env.JWT_EXPIRATION || '24h',
  issuer: process.env.JWT_ISSUER || 'mcp-todo-connector'
});

console.log('JWT Token:', token);
```

### Step 4: Use JWT Token

```bash
# Test with JWT token
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:3000/mcp/tools
```

## OAuth 2.0 Integration

For enterprise-grade authentication:

### Supported Providers

- **Microsoft Azure AD**: Enterprise identity management
- **Google OAuth**: Google account integration
- **GitHub OAuth**: Developer-friendly authentication
- **Auth0**: Universal identity platform
- **Custom OAuth**: Your own OAuth 2.0 provider

### Configuration Example (Azure AD)

```env
# OAuth 2.0 Configuration
AUTH_METHOD=oauth2
OAUTH_PROVIDER=azure
OAUTH_CLIENT_ID=your-client-id
OAUTH_CLIENT_SECRET=your-client-secret
OAUTH_TENANT_ID=your-tenant-id
OAUTH_REDIRECT_URI=http://localhost:3000/auth/callback
```

### Setup Steps

1. **Register Application** with your OAuth provider
2. **Configure Redirect URIs** in provider settings
3. **Set Environment Variables** with client credentials
4. **Test OAuth Flow** using browser-based authentication

## Security Best Practices

### Environment Security

```bash
# Set proper file permissions for .env
chmod 600 .env

# Never commit .env to version control
echo ".env" >> .gitignore
```

### API Key Management

- **Rotate Keys Regularly**: Change API keys every 90 days
- **Use Strong Keys**: Minimum 32 characters, cryptographically random
- **Limit Scope**: Use different keys for different environments
- **Monitor Usage**: Log and audit API key usage

### JWT Security

- **Strong Secrets**: Use cryptographically secure random secrets
- **Short Expiration**: Keep token lifetime as short as practical
- **Secure Storage**: Store secrets in secure key management systems
- **Validate Claims**: Always validate issuer, audience, and expiration

### Network Security

```env
# HTTPS Configuration (Production)
HTTPS_ENABLED=true
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem

# CORS Configuration
CORS_ORIGIN=https://your-frontend-domain.com
CORS_METHODS=GET,POST,PUT,DELETE
CORS_HEADERS=Content-Type,Authorization
```

## Testing Authentication

### Automated Testing

Create test scripts for each authentication method:

```bash
#!/bin/bash
# test-auth.sh

# Test no authentication
echo "Testing no authentication..."
curl -s http://localhost:3000/health

# Test API key authentication
echo "Testing API key authentication..."
curl -s -H "Authorization: Bearer $API_KEY" http://localhost:3000/mcp/tools

# Test JWT authentication
echo "Testing JWT authentication..."
curl -s -H "Authorization: Bearer $JWT_TOKEN" http://localhost:3000/mcp/tools
```

### Manual Testing

Use tools like Postman, Insomnia, or curl to test authentication:

1. **No Auth Request**: Should work for public endpoints
2. **Invalid Auth**: Should return 401 Unauthorized
3. **Valid Auth**: Should return expected data
4. **Expired Auth**: Should return 401 Unauthorized

## Troubleshooting

### Common Issues

#### "Invalid API Key" Error
```bash
# Check if API key is set correctly
echo $API_KEY

# Verify key format (should be 64 hex characters for recommended setup)
echo $API_KEY | wc -c  # Should output 65 (64 chars + newline)
```

#### "JWT Malformed" Error
```bash
# Validate JWT token structure
echo $JWT_TOKEN | cut -d'.' -f1 | base64 -d  # Decode header
echo $JWT_TOKEN | cut -d'.' -f2 | base64 -d  # Decode payload
```

#### "CORS Error" in Browser
```env
# Add your frontend domain to CORS settings
CORS_ORIGIN=http://localhost:3000,https://your-app.com
```

### Debug Mode

Enable authentication debugging:

```env
# Enable auth debugging
DEBUG=mcp:auth,mcp:*
LOG_LEVEL=debug
AUTH_DEBUG=true
```

### Log Analysis

Check authentication logs:

```bash
# View authentication logs
tail -f logs/server.log | grep -i auth

# Filter for authentication errors
grep "401\|403\|auth" logs/server.log
```

## Integration Examples

### MCP Client Configuration

Example configuration for popular MCP clients:

#### Claude Desktop
```json
{
  "mcpServers": {
    "todo-connector": {
      "command": "node",
      "args": ["path/to/mcp-todo-connector/index.js"],
      "env": {
        "API_KEY": "your-api-key-here"
      }
    }
  }
}
```

#### Custom Client
```javascript
// client.js
const { Client } = require('@modelcontextprotocol/sdk/client');

const client = new Client({
  name: 'todo-client',
  version: '1.0.0'
}, {
  capabilities: {
    tools: {},
    resources: {}
  }
});

// Add authentication header
client.setRequestInterceptor((request) => {
  request.headers = {
    ...request.headers,
    'Authorization': `Bearer ${process.env.API_KEY}`
  };
  return request;
});
```

## Production Deployment

### Environment Variables

```env
# Production Authentication Settings
NODE_ENV=production
AUTH_METHOD=jwt
JWT_SECRET=your-production-jwt-secret
API_RATE_LIMIT=100
AUTH_TIMEOUT=30s
```

### Security Headers

```env
# Security Headers
SECURITY_HEADERS=true
HSTS_MAX_AGE=31536000
CSP_POLICY=default-src 'self'
X_FRAME_OPTIONS=DENY
```

### Monitoring

```env
# Authentication Monitoring
AUTH_LOGGING=true
FAILED_AUTH_THRESHOLD=5
RATE_LIMIT_WINDOW=15m
ALERT_WEBHOOK=https://your-monitoring-service.com/webhook
```

## Support

For authentication-related issues:

1. **Check Logs**: Review server logs for authentication errors
2. **Verify Configuration**: Ensure environment variables are set correctly
3. **Test Connectivity**: Verify network connectivity and firewall settings
4. **Update Dependencies**: Keep authentication libraries up to date

### Getting Help

- 📧 **Email**: auth-support@cloudboostup.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/CloudBoostUP/mcp-todo-connector/issues)
- 📖 **Documentation**: [Authentication Wiki](https://github.com/CloudBoostUP/mcp-todo-connector/wiki/Authentication)

---

**Last Updated**: January 2025  
**Version**: 1.0  
**Security Review**: Pending

*This authentication guide should be reviewed and updated regularly to maintain security best practices.*