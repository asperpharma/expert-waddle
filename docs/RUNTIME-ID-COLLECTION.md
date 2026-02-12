# Runtime ID Collection Checklist

This document provides a unified checklist and guidance for capturing runtime-generated identifiers across various platforms and services. These IDs are critical for debugging, auditing, support ticketing, and incident tracking.

## Overview

Runtime-generated IDs are unique identifiers created dynamically during application execution, deployment, or API interactions. Common examples include:

- **Supabase**: UUID primary keys, request IDs, session IDs
- **Vercel**: Build IDs, deployment IDs, request IDs
- **API Responses**: Request IDs, transaction IDs, correlation IDs
- **Browser/DevTools**: Network request IDs, console error IDs

## Why Collect Runtime IDs?

- **Debugging**: Quickly locate specific requests, errors, or database records
- **Support Tickets**: Provide precise identifiers to support teams
- **Auditing**: Track changes and operations across systems
- **Incident Response**: Correlate events across different services
- **Performance Analysis**: Identify slow queries or problematic deployments

## Collection Checklist

### 1. Supabase Runtime IDs

#### Database Record IDs (UUIDs)
- [ ] Capture UUID primary keys when creating records
- [ ] Log UUIDs in error messages for failed operations
- [ ] Store UUIDs in application state for reference
- [ ] Include UUIDs in support ticket descriptions

**Example Locations:**
```javascript
// When creating a record
const { data, error } = await supabase
  .from('products')
  .insert({ name: 'Product' })
  .select('id');
console.log('Created record ID:', data[0].id);
```

#### Supabase Request IDs
- [ ] Check response headers for `x-request-id`
- [ ] Log request IDs for failed API calls
- [ ] Correlate request IDs with error messages

**Dashboard Access:**
- Navigate to [Supabase Dashboard](https://app.supabase.com)
- Select your project → Logs → API Logs
- Filter by request ID or timestamp

#### Query Supabase IDs from Database
Use the provided PowerShell script at `scripts/query-supabase-ids.ps1` to query IDs directly from your Postgres database.

### 2. Vercel Deployment and Build IDs

#### Deployment IDs
- [ ] Note deployment ID from Vercel dashboard after each deploy
- [ ] Capture deployment ID from Vercel CLI output
- [ ] Include deployment ID in bug reports related to specific versions
- [ ] Tag deployment IDs with corresponding git commit SHAs

**Dashboard Access:**
- Go to [Vercel Dashboard](https://vercel.com/dashboard)
- Select your project → Deployments
- Click on a deployment to see its unique ID

#### Build IDs
- [ ] Log build ID from CI/CD pipeline outputs
- [ ] Cross-reference build IDs with deployment IDs
- [ ] Track build IDs for build failures

**CLI Usage:**
Use the provided shell script at `scripts/vercel-deployment-ids.sh` to list deployment IDs using the Vercel CLI.

### 3. Browser and DevTools Runtime IDs

#### Network Request IDs
- [ ] Open DevTools (F12) → Network tab
- [ ] Look for `x-request-id`, `x-trace-id`, or similar headers
- [ ] Copy request ID from failed network calls
- [ ] Save request ID alongside error screenshots

**Steps:**
1. Open browser DevTools (F12 or Cmd+Option+I)
2. Navigate to Network tab
3. Find the failed request
4. Click on it → Headers tab
5. Look for request/trace ID headers

#### Console Error IDs
- [ ] Check console for error objects with IDs
- [ ] Use `collectRuntimeIds.js` helper to automatically log error IDs
- [ ] Screenshot console errors with visible timestamps and IDs

**Implementation:**
Use the provided JavaScript function at `src/lib/collectRuntimeIds.js` to automatically log runtime IDs during errors.

### 4. API Response Runtime IDs

#### Generic API Request IDs
- [ ] Parse response headers for request/trace IDs
- [ ] Log request IDs in catch blocks
- [ ] Store request IDs in error tracking systems (e.g., Sentry)
- [ ] Include request IDs in retry logic

**Example:**
```javascript
try {
  const response = await fetch('/api/endpoint');
  const requestId = response.headers.get('x-request-id');
  console.log('API Request ID:', requestId);
} catch (error) {
  console.error('Failed request ID:', error.requestId);
}
```

## Sample Scripts and Utilities

### Automated ID Collection

1. **JavaScript Helper** (`src/lib/collectRuntimeIds.js`)
   - Automatically logs error and request IDs to console
   - Integrates with fetch/axios interceptors
   - Useful during development and debugging

2. **Supabase Query Script** (`scripts/query-supabase-ids.ps1`)
   - PowerShell script to query Supabase UUIDs from Postgres
   - Requires Supabase connection string
   - Useful for bulk ID retrieval and auditing

3. **Vercel CLI Script** (`scripts/vercel-deployment-ids.sh`)
   - Shell script to list recent Vercel deployment IDs
   - Uses Vercel CLI (`vercel ls`)
   - Useful for CI/CD integration and tracking deployments

## Best Practices

1. **Always Log IDs**: Include runtime IDs in all error logs and monitoring
2. **Centralize Collection**: Use utilities like `collectRuntimeIds.js` to standardize ID logging
3. **Document ID Sources**: Note where each ID came from (Supabase, Vercel, API, etc.)
4. **Correlate IDs**: Link related IDs together (e.g., deployment ID + request ID)
5. **Include in Reports**: Always include relevant IDs in bug reports and support tickets
6. **Automate Where Possible**: Use scripts and tools to automatically capture IDs
7. **Store Securely**: Treat IDs as potentially sensitive; don't expose in public logs

## Support and Troubleshooting

### When Reporting Issues:

Include these IDs where applicable:
- **Database Issue**: Supabase record UUID
- **API Error**: Request ID from response headers
- **Deployment Issue**: Vercel deployment ID and build ID
- **Frontend Error**: Browser console error ID, network request ID

### Dashboard References:

- **Supabase Dashboard**: https://app.supabase.com
  - Logs → API Logs (for request IDs)
  - Database → Tables (for record UUIDs)
  
- **Vercel Dashboard**: https://vercel.com/dashboard
  - Deployments (for deployment and build IDs)
  - Logs (for request IDs)

## Additional Resources

- [Supabase Logging Documentation](https://supabase.com/docs/guides/platform/logs)
- [Vercel Deployment Documentation](https://vercel.com/docs/deployments/overview)
- [Browser DevTools Network Analysis](https://developer.chrome.com/docs/devtools/network/)

---

**Note**: This checklist is part of the CI and launch documentation for improved debugging and support workflows.
