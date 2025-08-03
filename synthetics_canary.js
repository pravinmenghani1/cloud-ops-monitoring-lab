const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const pageLoadBlueprint = async function () {
    // Configure Synthetics
    const syntheticsConfig = {
        includeRequestHeaders: true,
        includeResponseHeaders: true,
        restrictedHeaders: [],
        restrictedUrlParameters: []
    };

    let page = await synthetics.getPage();

    // User Journey Step 1: Load main page
    const response1 = await synthetics.executeStep('loadMainPage', async function () {
        const response = await page.goto('http://3.92.55.245', {
            waitUntil: 'domcontentloaded',
            timeout: 30000
        });
        
        // Verify page loaded successfully
        if (response.status() !== 200) {
            throw new Error(`Page load failed with status: ${response.status()}`);
        }
        
        // Check for expected content
        const title = await page.title();
        log.info('Page title: ' + title);
        
        // Verify monitoring features are present
        const monitoringSection = await page.$('.metrics');
        if (!monitoringSection) {
            throw new Error('Monitoring section not found on page');
        }
        
        // Measure page load performance
        const performanceMetrics = await page.evaluate(() => {
            const perfData = performance.getEntriesByType('navigation')[0];
            return {
                loadTime: Math.round(perfData.loadEventEnd - perfData.fetchStart),
                domReady: Math.round(perfData.domContentLoadedEventEnd - perfData.fetchStart),
                firstPaint: performance.getEntriesByType('paint').find(entry => entry.name === 'first-paint')?.startTime || 0
            };
        });
        
        log.info('Performance metrics:', performanceMetrics);
        
        // Add custom CloudWatch metrics
        await synthetics.addUserAgentMetric('PageLoadTime', performanceMetrics.loadTime, 'Milliseconds');
        await synthetics.addUserAgentMetric('DOMReadyTime', performanceMetrics.domReady, 'Milliseconds');
        
        return response;
    });

    // User Journey Step 2: Test health check endpoint
    const response2 = await synthetics.executeStep('testHealthCheck', async function () {
        const response = await page.goto('http://3.92.55.245/health', {
            waitUntil: 'domcontentloaded',
            timeout: 10000
        });
        
        if (response.status() !== 200) {
            throw new Error(`Health check failed with status: ${response.status()}`);
        }
        
        const content = await page.content();
        if (!content.includes('healthy')) {
            throw new Error('Health check response does not contain expected content');
        }
        
        log.info('Health check passed');
        return response;
    });

    // User Journey Step 3: Test interactive elements
    const response3 = await synthetics.executeStep('testInteractiveElements', async function () {
        // Go back to main page
        await page.goto('http://3.92.55.245', {
            waitUntil: 'domcontentloaded',
            timeout: 30000
        });
        
        // Test button interactions if they exist
        const buttons = await page.$$('button');
        if (buttons.length > 0) {
            log.info(`Found ${buttons.length} buttons on page`);
            
            // Click first button and measure response time
            const startTime = Date.now();
            await buttons[0].click();
            const clickResponseTime = Date.now() - startTime;
            
            await synthetics.addUserAgentMetric('ButtonClickResponseTime', clickResponseTime, 'Milliseconds');
            log.info(`Button click response time: ${clickResponseTime}ms`);
        }
        
        // Test navigation links
        const links = await page.$$('a[href]');
        if (links.length > 0) {
            log.info(`Found ${links.length} links on page`);
            
            // Test internal links
            for (let i = 0; i < Math.min(links.length, 3); i++) {
                const href = await links[i].getAttribute('href');
                if (href && href.startsWith('/')) {
                    try {
                        const linkStartTime = Date.now();
                        await links[i].click();
                        await page.waitForLoadState('domcontentloaded', { timeout: 10000 });
                        const linkResponseTime = Date.now() - linkStartTime;
                        
                        await synthetics.addUserAgentMetric('LinkNavigationTime', linkResponseTime, 'Milliseconds');
                        log.info(`Link navigation time for ${href}: ${linkResponseTime}ms`);
                        
                        // Go back to main page
                        await page.goto('http://3.92.55.245', {
                            waitUntil: 'domcontentloaded',
                            timeout: 30000
                        });
                    } catch (error) {
                        log.warn(`Failed to test link ${href}: ${error.message}`);
                    }
                }
            }
        }
        
        return { status: 'success' };
    });

    // User Journey Step 4: Test error scenarios
    const response4 = await synthetics.executeStep('testErrorScenarios', async function () {
        // Test 404 page
        const response404 = await page.goto('http://3.92.55.245/nonexistent-page', {
            waitUntil: 'domcontentloaded',
            timeout: 10000
        });
        
        if (response404.status() !== 404) {
            log.warn(`Expected 404 for non-existent page, got ${response404.status()}`);
        } else {
            log.info('404 error handling works correctly');
        }
        
        // Test server response time under load
        const loadTestStartTime = Date.now();
        const promises = [];
        for (let i = 0; i < 5; i++) {
            promises.push(page.goto('http://3.92.55.245', {
                waitUntil: 'domcontentloaded',
                timeout: 30000
            }));
        }
        
        await Promise.all(promises);
        const loadTestTime = Date.now() - loadTestStartTime;
        
        await synthetics.addUserAgentMetric('LoadTestResponseTime', loadTestTime, 'Milliseconds');
        log.info(`Load test (5 concurrent requests) completed in: ${loadTestTime}ms`);
        
        return { status: 'success' };
    });

    // User Journey Step 5: Validate monitoring endpoints
    const response5 = await synthetics.executeStep('validateMonitoringEndpoints', async function () {
        // Test that monitoring features are working
        await page.goto('http://3.92.55.245', {
            waitUntil: 'domcontentloaded',
            timeout: 30000
        });
        
        // Check if RUM is loaded
        const rumLoaded = await page.evaluate(() => {
            return typeof window.AwsRumClient !== 'undefined';
        });
        
        if (rumLoaded) {
            log.info('RUM client is loaded and active');
            await synthetics.addUserAgentMetric('RUMClientLoaded', 1, 'Count');
        } else {
            log.warn('RUM client is not loaded');
            await synthetics.addUserAgentMetric('RUMClientLoaded', 0, 'Count');
        }
        
        // Check if performance monitoring is working
        const performanceAPI = await page.evaluate(() => {
            return typeof window.performance !== 'undefined' && 
                   typeof window.performance.getEntriesByType === 'function';
        });
        
        if (performanceAPI) {
            log.info('Performance API is available');
            await synthetics.addUserAgentMetric('PerformanceAPIAvailable', 1, 'Count');
        } else {
            log.warn('Performance API is not available');
            await synthetics.addUserAgentMetric('PerformanceAPIAvailable', 0, 'Count');
        }
        
        return { status: 'success' };
    });

    // Log summary of user journey
    log.info('User journey completed successfully');
    log.info('Steps executed:');
    log.info('1. Main page load - Status: ' + response1.status());
    log.info('2. Health check - Status: ' + response2.status());
    log.info('3. Interactive elements test - Completed');
    log.info('4. Error scenarios test - Completed');
    log.info('5. Monitoring validation - Completed');
    
    // Add overall success metric
    await synthetics.addUserAgentMetric('UserJourneySuccess', 1, 'Count');
};

exports.handler = async () => {
    return await synthetics.executeStep('pageLoadBlueprint', pageLoadBlueprint);
};
