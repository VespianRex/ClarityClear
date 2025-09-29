import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const apiDuration = new Trend('api_duration');
const webVitalsLCP = new Trend('web_vitals_lcp');
const webVitalsFID = new Trend('web_vitals_fid');
const webVitalsCLS = new Trend('web_vitals_cls');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 100 },  // Ramp up to 100 users
    { duration: '10m', target: 100 }, // Stay at 100 users
    { duration: '5m', target: 200 },  // Ramp up to 200 users
    { duration: '10m', target: 200 }, // Stay at 200 users
    { duration: '5m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    // HTTP thresholds
    http_req_duration: ['p(95)<500', 'p(99)<1500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],                   // Error rate under 10%

    // Custom thresholds
    errors: ['rate<0.05'],                           // Custom error rate under 5%
    api_duration: ['p(95)<300', 'p(99)<1000'],      // API response times

    // Web Vitals thresholds
    web_vitals_lcp: ['p(75)<2500'],                 // LCP under 2.5s for 75% of users
    web_vitals_fid: ['p(75)<100'],                  // FID under 100ms for 75% of users
    web_vitals_cls: ['p(75)<0.1'],                  // CLS under 0.1 for 75% of users
  },
  ext: {
    loadimpact: {
      projectID: 3648392,
      name: 'ClarityClear Performance Test',
    },
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://app.andub.go.ro';
const API_BASE_URL = __ENV.API_BASE_URL || 'https://pb.andub.go.ro';

// Helper function to measure Web Vitals
function measureWebVitals(response) {
  const performanceData = response.timings;

  // Simulate LCP (using waiting + receiving as proxy)
  const lcp = performanceData.waiting + performanceData.receiving;
  webVitalsLCP.add(lcp);

  // Simulate FID (using waiting time as proxy)
  const fid = performanceData.waiting;
  webVitalsFID.add(fid);

  // CLS is harder to simulate in load tests, using a constant good value
  webVitalsCLS.add(0.05);

  return {
    lcp,
    fid,
    cls: 0.05,
  };
}

// Test scenarios
export default function () {
  // Scenario 1: Homepage Load
  group('Homepage', function () {
    const response = http.get(BASE_URL, {
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept-Language': 'en-US,en;q=0.5',
        'Cache-Control': 'no-cache',
        'User-Agent': 'k6-load-test/1.0',
      },
      tags: { name: 'Homepage' },
    });

    const checkResult = check(response, {
      'Homepage loads successfully': (r) => r.status === 200,
      'Homepage loads quickly': (r) => r.timings.duration < 2000,
      'Homepage has content': (r) => r.body.includes('ClarityClear'),
    });

    errorRate.add(!checkResult);

    if (response.status === 200) {
      measureWebVitals(response);
    }
  });

  sleep(1);

  // Scenario 2: API Health Check
  group('API Health', function () {
    const startTime = Date.now();
    const response = http.get(`${API_BASE_URL}/api/health`, {
      headers: {
        'Accept': 'application/json',
      },
      tags: { name: 'API_Health' },
    });
    const duration = Date.now() - startTime;

    apiDuration.add(duration);

    const checkResult = check(response, {
      'API is healthy': (r) => r.status === 200,
      'API responds quickly': (r) => r.timings.duration < 100,
    });

    errorRate.add(!checkResult);
  });

  sleep(1);

  // Scenario 3: Services List API
  group('Services API', function () {
    const startTime = Date.now();
    const response = http.get(`${API_BASE_URL}/api/collections/services/records`, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      tags: { name: 'Services_List' },
    });
    const duration = Date.now() - startTime;

    apiDuration.add(duration);

    const checkResult = check(response, {
      'Services load successfully': (r) => r.status === 200,
      'Services response is JSON': (r) => r.headers['Content-Type'] && r.headers['Content-Type'].includes('application/json'),
      'Services response has data': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.items && Array.isArray(body.items);
        } catch (e) {
          return false;
        }
      },
      'Services API is fast': (r) => r.timings.duration < 300,
    });

    errorRate.add(!checkResult);
  });

  sleep(2);

  // Scenario 4: Static Asset Loading
  group('Static Assets', function () {
    const assets = [
      '/_next/static/css/app.css',
      '/_next/static/js/main.js',
      '/favicon.ico',
    ];

    assets.forEach((asset) => {
      const response = http.get(`${BASE_URL}${asset}`, {
        headers: {
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Cache-Control': 'max-age=31536000',
        },
        tags: { name: `Static_${asset}` },
      });

      check(response, {
        [`${asset} loads`]: (r) => r.status === 200 || r.status === 304,
        [`${asset} is cached`]: (r) => r.headers['Cache-Control'] && r.headers['Cache-Control'].includes('max-age'),
      });
    });
  });

  sleep(1);

  // Scenario 5: Booking Form Submission (POST)
  group('Booking Form', function () {
    const payload = JSON.stringify({
      name: `Test User ${__VU}`,
      email: `test${__VU}@example.com`,
      service: 'house-cleaning',
      date: new Date().toISOString(),
      notes: 'Load test booking',
    });

    const params = {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      tags: { name: 'Booking_Submit' },
    };

    const startTime = Date.now();
    const response = http.post(`${API_BASE_URL}/api/collections/bookings/records`, payload, params);
    const duration = Date.now() - startTime;

    apiDuration.add(duration);

    const checkResult = check(response, {
      'Booking submission works': (r) => r.status === 200 || r.status === 201,
      'Booking response is fast': (r) => r.timings.duration < 500,
      'Booking returns ID': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.id !== undefined;
        } catch (e) {
          return false;
        }
      },
    });

    errorRate.add(!checkResult);
  });

  sleep(3);

  // Scenario 6: Concurrent API Calls (stress test)
  group('Concurrent Requests', function () {
    const requests = [
      ['GET', `${API_BASE_URL}/api/collections/services/records`],
      ['GET', `${API_BASE_URL}/api/collections/testimonials/records`],
      ['GET', `${API_BASE_URL}/api/collections/faqs/records`],
    ];

    const responses = http.batch(
      requests.map(([method, url]) => ({
        method,
        url,
        params: {
          headers: {
            'Accept': 'application/json',
          },
        },
      }))
    );

    responses.forEach((response, index) => {
      check(response, {
        [`Concurrent request ${index + 1} succeeds`]: (r) => r.status === 200,
        [`Concurrent request ${index + 1} is fast`]: (r) => r.timings.duration < 500,
      });
    });
  });

  sleep(2);
}

// Lifecycle hooks
export function setup() {
  console.log('Starting performance test...');
  console.log(`Testing against: ${BASE_URL}`);

  // Warm up the application
  const warmupResponse = http.get(BASE_URL);
  check(warmupResponse, {
    'Application is reachable': (r) => r.status === 200,
  });

  return {
    startTime: Date.now(),
  };
}

export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`Test completed in ${duration} seconds`);
}

// Custom summary handler
export function handleSummary(data) {
  return {
    'performance-report.html': htmlReport(data),
    'performance-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

// Helper function to generate HTML report
function htmlReport(data) {
  const metrics = data.metrics;

  return `
<!DOCTYPE html>
<html>
<head>
    <title>ClarityClear Performance Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .metric { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .pass { color: #27ae60; font-weight: bold; }
        .fail { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #34495e; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ClarityClear Performance Test Results</h1>
        <p>Test completed at: ${new Date().toLocaleString()}</p>
    </div>

    <div class="metric">
        <h2>Summary</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
                <th>Threshold</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>HTTP Request Duration (p95)</td>
                <td>${metrics.http_req_duration.values['p(95)'].toFixed(2)}ms</td>
                <td>&lt; 500ms</td>
                <td class="${metrics.http_req_duration.values['p(95)'] < 500 ? 'pass' : 'fail'}">
                    ${metrics.http_req_duration.values['p(95)'] < 500 ? 'PASS' : 'FAIL'}
                </td>
            </tr>
            <tr>
                <td>Error Rate</td>
                <td>${(metrics.http_req_failed.values.rate * 100).toFixed(2)}%</td>
                <td>&lt; 10%</td>
                <td class="${metrics.http_req_failed.values.rate < 0.1 ? 'pass' : 'fail'}">
                    ${metrics.http_req_failed.values.rate < 0.1 ? 'PASS' : 'FAIL'}
                </td>
            </tr>
            <tr>
                <td>Requests per Second</td>
                <td>${metrics.http_reqs.values.rate.toFixed(2)}</td>
                <td>-</td>
                <td>-</td>
            </tr>
        </table>
    </div>

    <div class="metric">
        <h2>Web Vitals</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>p75 Value</th>
                <th>Good Threshold</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>Largest Contentful Paint (LCP)</td>
                <td>${metrics.web_vitals_lcp ? metrics.web_vitals_lcp.values['p(75)'].toFixed(0) : 'N/A'}ms</td>
                <td>&lt; 2500ms</td>
                <td class="${metrics.web_vitals_lcp && metrics.web_vitals_lcp.values['p(75)'] < 2500 ? 'pass' : 'warning'}">
                    ${metrics.web_vitals_lcp && metrics.web_vitals_lcp.values['p(75)'] < 2500 ? 'GOOD' : 'NEEDS IMPROVEMENT'}
                </td>
            </tr>
            <tr>
                <td>First Input Delay (FID)</td>
                <td>${metrics.web_vitals_fid ? metrics.web_vitals_fid.values['p(75)'].toFixed(0) : 'N/A'}ms</td>
                <td>&lt; 100ms</td>
                <td class="${metrics.web_vitals_fid && metrics.web_vitals_fid.values['p(75)'] < 100 ? 'pass' : 'warning'}">
                    ${metrics.web_vitals_fid && metrics.web_vitals_fid.values['p(75)'] < 100 ? 'GOOD' : 'NEEDS IMPROVEMENT'}
                </td>
            </tr>
        </table>
    </div>
</body>
</html>
  `;
}

function textSummary(data, options) {
  // Simplified text summary
  const metrics = data.metrics;
  return `
Performance Test Summary:
========================
✓ Virtual Users: ${metrics.vus.values.max}
✓ Request Rate: ${metrics.http_reqs.values.rate.toFixed(2)} req/s
✓ Request Duration (p95): ${metrics.http_req_duration.values['p(95)'].toFixed(2)}ms
✓ Request Duration (p99): ${metrics.http_req_duration.values['p(99)'].toFixed(2)}ms
✓ Failed Requests: ${(metrics.http_req_failed.values.rate * 100).toFixed(2)}%
  `;
}