// This script creates a GitHub Check for test results
// It's designed to be used with the actions/github-script action

module.exports = async ({github, context, core, reportDir, testType}) => {
  const fs = require('fs');
  
  if (!reportDir) reportDir = '.';
  if (!testType) testType = 'Test';
  
  // Get PR information or commit SHA
  const pr = context.payload.pull_request;
  const sha = pr && pr.head.sha ? pr.head.sha : context.sha;
  
  // Read the generated HTML
  let reportSummary, reportDetail;
  
  try {
    reportSummary = fs.readFileSync(`${reportDir}/report-summary.html`, 'utf8');
    reportDetail = fs.readFileSync(`${reportDir}/report-detail.html`, 'utf8');
  } catch (error) {
    core.error(`Error reading report files: ${error.message}`);
    throw error;
  }
  
  // GitHub Checks has a character limit of 65535
  const charactersLimit = 65535;
  
  if (reportSummary.length > charactersLimit) {
    console.warn(`Summary will be truncated (exceeded ${charactersLimit} characters)`);
    reportSummary = reportSummary.substring(0, charactersLimit);
  }
  
  if (reportDetail.length > charactersLimit) {
    console.warn(`Detail will be truncated (exceeded ${charactersLimit} characters)`);
    reportDetail = reportDetail.substring(0, charactersLimit);
  }
  
  // Read test statistics from JSON summary
  let testStats;
  try {
    const summaryJson = fs.readFileSync(`${reportDir}/test-summary.json`, 'utf8');
    testStats = JSON.parse(summaryJson);
  } catch (error) {
    core.warning(`Error reading test summary JSON: ${error.message}`);
    // Fallback to zero values
    testStats = {
      total_tests: 0,
      passed_tests: 0,
      failed_tests: 0,
      success_rate: 0
    };
  }
  
  // Set conclusion based on failed tests count
  const conclusion = testStats.failed_tests > 0 ? 'failure' : 'success';
  
  // Format the success rate to 1 decimal place
  const successRate = typeof testStats.success_rate === 'number' 
    ? testStats.success_rate.toFixed(1) 
    : parseFloat(testStats.success_rate).toFixed(1);
  
  // Create the check
  try {
    await github.rest.checks.create({
      owner: context.repo.owner,
      repo: context.repo.repo,
      name: `${testType} Results`,
      head_sha: sha,
      status: 'completed',
      conclusion: conclusion,
      output: {
        title: `${testType} Results: ${testStats.passed_tests}/${testStats.total_tests} tests passed (${successRate}%)`,
        summary: reportSummary,
        text: reportDetail
      }
    });
    
    core.info(`Created GitHub Check for ${testType} with ${testStats.passed_tests}/${testStats.total_tests} tests passed (${successRate}%)`);
  } catch (error) {
    core.error(`Error creating GitHub Check: ${error.message}`);
    throw error;
  }
}; 