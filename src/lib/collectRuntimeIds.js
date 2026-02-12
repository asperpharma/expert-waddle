/**
 * Runtime ID Collection Utility
 * 
 * This module provides helper functions to automatically collect and log
 * runtime-generated identifiers (request IDs, error IDs, etc.) during
 * API calls and network failures.
 * 
 * Usage:
 * - Import and use `logErrorWithIds` in catch blocks
 * - Use `setupFetchInterceptor` to automatically log request IDs from fetch calls (browser only)
 * - Use `setupAxiosInterceptor` to automatically log request IDs from axios calls
 */

// Common request/trace ID header names used across different services
const ID_HEADERS = [
  'x-request-id',
  'x-trace-id',
  'x-correlation-id',
  'x-amzn-requestid',
  'x-amzn-trace-id',
  'request-id',
  'trace-id'
];

/**
 * Extracts common request/trace ID headers from a Response or Headers object
 * @param {Response|Headers} responseOrHeaders - Fetch Response object or Headers
 * @returns {Object} Object containing extracted IDs
 */
export function extractRequestIds(responseOrHeaders) {
  const headers = responseOrHeaders instanceof Response 
    ? responseOrHeaders.headers 
    : responseOrHeaders;

  const ids = {};
  
  ID_HEADERS.forEach(header => {
    const value = headers.get(header);
    if (value) {
      ids[header] = value;
    }
  });

  return ids;
}

/**
 * Logs an error with extracted runtime IDs
 * @param {Error} error - The error object
 * @param {Response} [response] - Optional Response object to extract IDs from
 * @param {Object} [additionalIds] - Additional IDs to log (e.g., Supabase UUIDs)
 */
export function logErrorWithIds(error, response = null, additionalIds = {}) {
  const ids = response ? extractRequestIds(response) : {};
  
  console.error('=== Error with Runtime IDs ===');
  console.error('Error:', error.message);
  console.error('Stack:', error.stack);
  
  if (Object.keys(ids).length > 0) {
    console.error('Request IDs:', JSON.stringify(ids, null, 2));
  }
  
  if (Object.keys(additionalIds).length > 0) {
    console.error('Additional IDs:', JSON.stringify(additionalIds, null, 2));
  }
  
  console.error('Timestamp:', new Date().toISOString());
  console.error('==============================');
  
  return { error, ids, additionalIds };
}

/**
 * Sets up a global fetch interceptor to log request IDs
 * This wraps the native fetch function to automatically extract and log IDs
 * 
 * NOTE: This function is browser-only and requires the window object.
 * It will throw an error if used in Node.js environments.
 */
export function setupFetchInterceptor() {
  if (typeof window === 'undefined' || !window.fetch) {
    throw new Error('setupFetchInterceptor is only available in browser environments');
  }
  
  const originalFetch = window.fetch;
  
  window.fetch = async function(...args) {
    try {
      const response = await originalFetch(...args);
      
      // Log request IDs for non-2xx responses
      if (!response.ok) {
        const ids = extractRequestIds(response);
        if (Object.keys(ids).length > 0) {
          console.warn('API Error - Request IDs:', {
            url: args[0],
            status: response.status,
            ids
          });
        }
      }
      
      return response;
    } catch (error) {
      console.error('Network Error:', {
        url: args[0],
        error: error.message
      });
      throw error;
    }
  };
  
  console.log('Fetch interceptor installed for runtime ID collection');
}

/**
 * Sets up Axios interceptors to log request IDs
 * @param {Object} axiosInstance - Axios instance to intercept
 */
export function setupAxiosInterceptor(axiosInstance) {
  // Response interceptor
  axiosInstance.interceptors.response.use(
    (response) => {
      // Success response - optionally log IDs for debugging
      return response;
    },
    (error) => {
      // Error response - extract and log IDs
      if (error.response) {
        const ids = {};
        const headers = error.response.headers;
        
        ID_HEADERS.forEach(key => {
          if (headers[key]) {
            ids[key] = headers[key];
          }
        });
        
        if (Object.keys(ids).length > 0) {
          console.error('Axios Error - Request IDs:', {
            url: error.config?.url,
            method: error.config?.method,
            status: error.response.status,
            ids
          });
        }
      }
      
      return Promise.reject(error);
    }
  );
  
  console.log('Axios interceptor installed for runtime ID collection');
}

/**
 * Creates a Supabase error handler that logs UUIDs and request IDs
 * @param {Object} result - Supabase query result (with data, error)
 * @param {string} operation - Description of the operation (e.g., "insert product")
 * @returns {Object} The original result object
 */
export function logSupabaseError(result, operation = 'operation') {
  const { data, error } = result;
  
  if (error) {
    console.error('=== Supabase Error ===');
    console.error('Operation:', operation);
    console.error('Error:', error.message);
    console.error('Error Code:', error.code);
    console.error('Error Details:', error.details);
    console.error('Error Hint:', error.hint);
    
    // Log any IDs from the data if available
    if (data) {
      if (Array.isArray(data)) {
        console.error('Record IDs:', data.map(item => item.id).filter(Boolean));
      } else if (data.id) {
        console.error('Record ID:', data.id);
      }
    }
    
    console.error('Timestamp:', new Date().toISOString());
    console.error('======================');
  }
  
  return result;
}

/**
 * Utility to help format IDs for support tickets
 * @param {Object} ids - Object containing various runtime IDs
 * @returns {string} Formatted string suitable for pasting into support tickets
 */
export function formatIdsForSupport(ids) {
  const lines = ['=== Runtime IDs for Support ==='];
  
  if (ids.requestId) lines.push(`Request ID: ${ids.requestId}`);
  if (ids.traceId) lines.push(`Trace ID: ${ids.traceId}`);
  if (ids.correlationId) lines.push(`Correlation ID: ${ids.correlationId}`);
  if (ids.recordId) lines.push(`Database Record ID: ${ids.recordId}`);
  if (ids.deploymentId) lines.push(`Deployment ID: ${ids.deploymentId}`);
  if (ids.buildId) lines.push(`Build ID: ${ids.buildId}`);
  
  lines.push(`Timestamp: ${new Date().toISOString()}`);
  lines.push('================================');
  
  return lines.join('\n');
}

export default {
  extractRequestIds,
  logErrorWithIds,
  setupFetchInterceptor,
  setupAxiosInterceptor,
  logSupabaseError,
  formatIdsForSupport
};
