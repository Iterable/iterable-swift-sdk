#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import sys
import tempfile
import webbrowser
import traceback
from pathlib import Path
import re


class Parser:
    def __init__(self, bundle_path):
        self.bundle_path = bundle_path

    def parse(self, reference=None):
        """Parse JSON data from xcresulttool"""
        json_str = self._to_json(reference)
        root = json.loads(json_str)
        return self._parse_object(root)

    def export_code_coverage(self):
        """Export code coverage data in JSON format"""
        args = ['xcrun', 'xccov', 'view', '--report', '--json', self.bundle_path]
        
        try:
            result = subprocess.run(args, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error exporting code coverage: {e.stderr}")
            return ""

    def _to_json(self, reference=None):
        """Convert xcresult data to JSON"""
        args = [
            'xcrun', 'xcresulttool', 'get', 'object',
            '--legacy',
            '--path', self.bundle_path,
            '--format', 'json'
        ]
        
        if reference:
            args.extend(['--id', reference])
        
        try:
            result = subprocess.run(args, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error getting xcresult JSON: {e.stderr}")
            return "{}"

    def _parse_object(self, element):
        """Parse xcresult JSON object structure"""
        obj = {}

        if not isinstance(element, dict):
            return element

        for key, value in element.items():
            if isinstance(value, dict):
                if '_value' in value:
                    obj[key] = self._parse_primitive(value)
                elif '_values' in value:
                    obj[key] = self._parse_array(value)
                elif key == '_type':
                    continue
                else:
                    obj[key] = self._parse_object(value)
            else:
                obj[key] = value

        return obj

    def _parse_array(self, array_element):
        """Parse array elements from xcresult JSON"""
        if not isinstance(array_element, dict) or '_values' not in array_element:
            return array_element
            
        result = []
        for array_value in array_element['_values']:
            obj = {}
            for key, value in array_value.items():
                if isinstance(value, dict):
                    if '_value' in value:
                        obj[key] = self._parse_primitive(value)
                    elif '_values' in value:
                        obj[key] = self._parse_array(value)
                    elif key == '_type' or key == '_value':
                        continue
                    else:
                        obj[key] = self._parse_object(value)
                else:
                    obj[key] = value
            result.append(obj)
        return result

    def _parse_primitive(self, element):
        """Parse primitive values from xcresult JSON"""
        if not isinstance(element, dict) or '_value' not in element:
            return element
            
        if '_type' in element and isinstance(element['_type'], dict) and '_name' in element['_type']:
            type_name = element['_type']['_name']
            if type_name == 'Int':
                try:
                    return int(element['_value'])
                except (ValueError, TypeError):
                    return 0
            elif type_name == 'Double':
                try:
                    return float(element['_value'])
                except (ValueError, TypeError):
                    return 0.0
            else:
                return element['_value']
        else:
            return element['_value']


class Formatter:
    def __init__(self, bundle_path, test_stats=None):
        self.bundle_path = bundle_path
        self.parser = Parser(bundle_path)
        self.test_stats = test_stats
        
        # Define status icons similar to TypeScript version
        self.passed_icon = "✅"  # In TypeScript this is an image
        self.failed_icon = "❌"  # In TypeScript this is an image
        self.skipped_icon = "⏩"  # In TypeScript this is an image
        self.expected_failure_icon = "⚠️"  # In TypeScript this is an image

    def format(self, options=None):
        """Format xcresult data into HTML report"""
        if options is None:
            options = {
                'showPassedTests': True,
                'showCodeCoverage': True
            }
            
        try:
            # Parse the main invocation record
            actions_invocation_record = self.parser.parse()
            
            # Create report structure
            report = {
                'entityName': None,
                'creatingWorkspaceFilePath': None,
                'testStatus': 'neutral',
                'annotations': [],
                'buildLog': None,
                'chapters': [],
                'codeCoverage': None
            }
            
            # Process metadata
            if 'metadataRef' in actions_invocation_record:
                metadata = self.parser.parse(actions_invocation_record['metadataRef']['id'])
                if 'schemeIdentifier' in metadata and 'entityName' in metadata['schemeIdentifier']:
                    report['entityName'] = metadata['schemeIdentifier']['entityName']
                if 'creatingWorkspaceFilePath' in metadata:
                    report['creatingWorkspaceFilePath'] = metadata['creatingWorkspaceFilePath']
            
            # Process actions
            if 'actions' in actions_invocation_record:
                for action in actions_invocation_record['actions']:
                    # Process test results
                    if 'actionResult' in action and 'testsRef' in action['actionResult']:
                        chapter = {
                            'title': action.get('title'),
                            'schemeCommandName': action.get('schemeCommandName', ''),
                            'runDestination': action.get('runDestination', {}),
                            'sections': {},
                            'summaries': [],
                            'details': []
                        }
                        report['chapters'].append(chapter)
                        
                        # Process test plan run summaries
                        action_test_plan_run_summaries = self.parser.parse(
                            action['actionResult']['testsRef']['id']
                        )
                        
                        for summary in action_test_plan_run_summaries.get('summaries', []):
                            for testable_summary in summary.get('testableSummaries', []):
                                if testable_summary.get('name'):
                                    # Collect all tests recursively
                                    all_tests = []
                                    self._collect_tests_recursively(testable_summary.get('tests', []), all_tests)
                                    
                                    chapter['sections'][testable_summary['name']] = {
                                        'summary': testable_summary,
                                        'details': all_tests
                                    }
                    
                    # Process code coverage if enabled
                    if options['showCodeCoverage'] and 'actionResult' in action and 'coverage' in action['actionResult']:
                        try:
                            code_coverage_json = self.parser.export_code_coverage()
                            if code_coverage_json:
                                code_coverage = json.loads(code_coverage_json)
                                report['codeCoverage'] = code_coverage
                        except Exception as e:
                            print(f"Error processing code coverage: {str(e)}")
            
            # Generate test summary HTML
            test_summary_html = self._generate_test_summary_html(report)
            
            # Generate test details HTML
            test_details_html = self._generate_test_details_html(report, options['showPassedTests'])
            
            # Generate code coverage HTML if available
            code_coverage_html = ""
            if options['showCodeCoverage'] and report['codeCoverage']:
                code_coverage_html = self._generate_code_coverage_html(report['codeCoverage'])
            
            return {
                'reportSummary': test_summary_html,
                'reportDetail': test_details_html,
                'codeCoverage': code_coverage_html,
                'testStatus': self._determine_test_status(report)
            }
            
        except Exception as e:
            print(f"Error formatting xcresult: {str(e)}")
            traceback.print_exc()
            return {
                'reportSummary': f"<h1>Error Formatting Test Results</h1>\n<p>{str(e)}</p>",
                'reportDetail': "",
                'codeCoverage': "",
                'testStatus': 'failure'
            }

    def _collect_tests_recursively(self, tests, result):
        """Collect tests recursively from nested test structure"""
        for test in tests:
            if isinstance(test, dict):
                if 'subtests' in test:
                    self._collect_tests_recursively(test['subtests'], result)
                else:
                    result.append(test)

    def _generate_test_summary_html(self, report):
        """Generate HTML for test summary"""
        lines = []
        
        # Process chapters (test configurations)
        for chapter in report['chapters']:
            # Generate chapter title
            title = chapter.get('title', '')
            if not title and report['entityName']:
                title = f"{chapter.get('schemeCommandName', '')} {report['entityName']}"
            else:
                title = chapter.get('schemeCommandName', 'Tests')
                
            lines.append(f"<h2>{title}</h2>")
            
            # If we have test stats from xcresulttool, use those instead of trying to
            # count from the XCResult structure, which is often incomplete
            if self.test_stats:
                total_tests = self.test_stats['total_tests']
                passed_tests = self.test_stats['passed_tests']
                failed_tests = self.test_stats['failed_tests']
                skipped_tests = self.test_stats['skipped_tests']
                expected_failures = 0  # Not tracked in the summary stats
                
                # Duration is not in the summary JSON but we can estimate
                total_duration = 0
                for section_name, section in chapter['sections'].items():
                    for test in section.get('details', []):
                        if isinstance(test, dict) and 'duration' in test:
                            total_duration += test['duration']
                
                # Generate summary table with accurate test counts
                lines.append("<table>")
                lines.append("<tr>")
                lines.append("<th>Total</th>")
                lines.append("<th>Passed</th>")
                lines.append("<th>Failed</th>")
                lines.append("<th>Skipped</th>")
                lines.append("<th>Expected Failures</th>")
                lines.append("<th>Duration</th>")
                lines.append("</tr>")
                
                lines.append("<tr>")
                lines.append(f"<td>{total_tests}</td>")
                lines.append(f"<td>{passed_tests}</td>")
                lines.append(f"<td>{failed_tests}</td>")
                lines.append(f"<td>{skipped_tests}</td>")
                lines.append(f"<td>{expected_failures}</td>")
                lines.append(f"<td>{total_duration:.2f}s</td>")
                lines.append("</tr>")
                lines.append("</table>")
                
            else:
                # Process test statistics the old way
                total_tests = 0
                passed_tests = 0
                failed_tests = 0
                skipped_tests = 0
                expected_failures = 0
                total_duration = 0
                
                # Collect statistics from all sections
                for section_name, section in chapter['sections'].items():
                    # Check if the summary has more direct test counts (often more reliable)
                    if 'summary' in section and isinstance(section['summary'], dict):
                        summary = section['summary']
                        if 'tests' in summary:
                            # Some XCResults provide test counts directly in summary
                            # Handle case where 'tests' might be a list instead of a number
                            tests_value = summary.get('tests', 0)
                            if isinstance(tests_value, list):
                                # If it's a list, try to get the length or first value
                                if len(tests_value) > 0:
                                    if isinstance(tests_value[0], dict) and '_value' in tests_value[0]:
                                        total_tests += tests_value[0]['_value']
                                    else:
                                        total_tests += len(tests_value)
                            else:
                                total_tests += tests_value
                            
                            # Handle failures which might also be lists
                            failures_value = summary.get('failures', 0)
                            if isinstance(failures_value, list):
                                if len(failures_value) > 0:
                                    if isinstance(failures_value[0], dict) and '_value' in failures_value[0]:
                                        failed_tests += failures_value[0]['_value']
                                    else:
                                        failed_tests += len(failures_value)
                            else:
                                failed_tests += failures_value
                            
                            # Handle skipped tests which might also be lists
                            skipped_value = summary.get('skippedTests', 0)
                            if isinstance(skipped_value, list):
                                if len(skipped_value) > 0:
                                    if isinstance(skipped_value[0], dict) and '_value' in skipped_value[0]:
                                        skipped_tests += skipped_value[0]['_value']
                                    else:
                                        skipped_tests += len(skipped_value)
                            else:
                                skipped_tests += skipped_value
                            
                            # Duration may be directly available too
                            if 'duration' in summary:
                                duration_value = summary.get('duration', 0)
                                if not isinstance(duration_value, (int, float)):
                                    # Try to convert non-numeric types to float
                                    try:
                                        duration_value = float(duration_value)
                                    except (ValueError, TypeError):
                                        duration_value = 0
                                total_duration += duration_value
                            
                            # If we found summary data, don't double-count via details
                            continue
                    
                    # If no summary data was found, try counting from details
                    for test in section.get('details', []):
                        if isinstance(test, dict) and 'testStatus' in test:
                            total_tests += 1
                            status = test['testStatus']
                            if status == 'Success':
                                passed_tests += 1
                            elif status == 'Failure':
                                failed_tests += 1
                            elif status == 'Skipped':
                                skipped_tests += 1
                            elif status == 'Expected Failure':
                                expected_failures += 1
                            
                            # Add duration
                            if 'duration' in test:
                                total_duration += test['duration']
                
                # If we got total tests from summaries but not passed tests, calculate it
                if total_tests > 0 and passed_tests == 0:
                    passed_tests = total_tests - failed_tests - skipped_tests - expected_failures
            
                # Generate summary table
                lines.append("<table>")
                lines.append("<tr>")
                lines.append("<th>Total</th>")
                lines.append("<th>Passed</th>")
                lines.append("<th>Failed</th>")
                lines.append("<th>Skipped</th>")
                lines.append("<th>Expected Failures</th>")
                lines.append("<th>Duration</th>")
                lines.append("</tr>")
                
                lines.append("<tr>")
                lines.append(f"<td>{total_tests}</td>")
                lines.append(f"<td>{passed_tests}</td>")
                lines.append(f"<td>{failed_tests}</td>")
                lines.append(f"<td>{skipped_tests}</td>")
                lines.append(f"<td>{expected_failures}</td>")
                lines.append(f"<td>{total_duration:.2f}s</td>")
                lines.append("</tr>")
                lines.append("</table>")
            
            # Process test environment
            if 'runDestination' in chapter and 'targetArchitecture' in chapter['runDestination']:
                lines.append("<h3>Test Environment</h3>")
                lines.append("<table>")
                
                # Extract device/simulator info
                if 'targetDeviceRecord' in chapter['runDestination']:
                    device = chapter['runDestination']['targetDeviceRecord']
                    
                    if 'modelName' in device:
                        lines.append("<tr>")
                        lines.append("<th>Device</th>")
                        lines.append(f"<td>{device.get('modelName', 'Unknown')}</td>")
                        lines.append("</tr>")
                    
                    if 'operatingSystemVersion' in device:
                        lines.append("<tr>")
                        lines.append("<th>OS Version</th>")
                        lines.append(f"<td>{device.get('operatingSystemVersion', 'Unknown')}</td>")
                        lines.append("</tr>")
                
                # Add architecture
                lines.append("<tr>")
                lines.append("<th>Architecture</th>")
                lines.append(f"<td>{chapter['runDestination'].get('targetArchitecture', 'Unknown')}</td>")
                lines.append("</tr>")
                
                lines.append("</table>")
        
        return "\n".join(lines)

    def _generate_test_details_html(self, report, show_passed_tests=True):
        """Generate HTML for test details"""
        lines = []
        
        for chapter in report['chapters']:
            lines.append("<h2>Test Details</h2>")
            
            # Process each section (testable)
            for section_name, section in chapter['sections'].items():
                lines.append(f"<h3>{section_name}</h3>")
                
                # Group test results by test class
                test_classes = {}
                for test in section['details']:
                    if isinstance(test, dict):
                        # Skip passed tests if not showing them
                        if not show_passed_tests and test.get('testStatus') == 'Success':
                            continue
                            
                        # Extract test class and name
                        test_class = None
                        test_name = test.get('name', 'Unknown Test')
                        
                        # Try to extract class name from test identifier
                        if 'identifier' in test:
                            parts = test['identifier'].split('/')
                            if len(parts) >= 2:
                                test_class = parts[-2]
                        
                        # If no class found, use a default
                        if not test_class:
                            test_class = "Tests"
                            
                        # Add to the appropriate class group
                        if test_class not in test_classes:
                            test_classes[test_class] = []
                        test_classes[test_class].append(test)
                
                # Sort classes alphabetically to match TypeScript behavior
                for class_name in sorted(test_classes.keys()):
                    tests = test_classes[class_name]
                    
                    # Create a unique ID for this class for anchoring
                    class_id = class_name.replace(' ', '_').replace('.', '_')
                    
                    lines.append(f'<h4 id="{class_id}">{class_name}</h4>')
                    lines.append('<table>')
                    
                    # Sort tests by name for consistent ordering
                    sorted_tests = sorted(tests, key=lambda t: t.get('name', ''))
                    
                    for test in sorted_tests:
                        status = test.get('testStatus', 'Unknown')
                        duration = test.get('duration', 0)
                        test_name = test.get('name', 'Unknown Test')
                        
                        # Choose icon based on status
                        icon = self.passed_icon if status == "Success" else \
                               self.failed_icon if status == "Failure" else \
                               self.skipped_icon if status == "Skipped" else \
                               self.expected_failure_icon
                        
                        # Create table row for test
                        test_id = f"{class_id}_{test_name.replace(' ', '_').replace('.', '_')}"
                        lines.append(f'<tr id="{test_id}">')
                        lines.append(f'<td>{icon}</td>')
                        lines.append(f'<td>{test_name}</td>')
                        lines.append(f'<td>{duration:.2f}s</td>')
                        lines.append('</tr>')
                        
                        # Add failure details if the test failed
                        if status == "Failure" and 'failureSummaries' in test:
                            for failure in test['failureSummaries']:
                                message = failure.get('message', 'Unknown failure')
                                file_path = failure.get('fileName', '')
                                line_number = failure.get('lineNumber', 0)
                                
                                location = f"{file_path}:{line_number}" if file_path and line_number else "Unknown location"
                                
                                lines.append('<tr>')
                                lines.append('<td></td>')  # Empty cell for alignment
                                lines.append('<td colspan="2">')
                                lines.append('<div class="failure">')
                                lines.append(f'<strong>Failure:</strong> {message}<br>')
                                lines.append(f'<code>{location}</code>')
                                lines.append('</div>')
                                lines.append('</td>')
                                lines.append('</tr>')
                    
                    lines.append('</table>')
        
        return "\n".join(lines)

    def _generate_code_coverage_html(self, code_coverage):
        """Generate HTML for code coverage"""
        if not code_coverage:
            return ""
            
        lines = ["<h2>Code Coverage</h2>"]
        
        # Overall coverage
        total_covered = code_coverage.get('coveredLines', 0)
        total_executable = code_coverage.get('executableLines', 0)
        total_coverage = code_coverage.get('lineCoverage', 0) * 100
        
        lines.append("<table>")
        lines.append("<tr>")
        lines.append("<th width='344px'>Target</th>")
        lines.append("<th colspan='2'>Coverage</th>")
        lines.append("<th width='100px'>Covered</th>")
        lines.append("<th width='100px'>Executable</th>")
        lines.append("</tr>")
        
        # Add total row
        lines.append("<tr>")
        lines.append("<td>Total</td>")
        
        # Coverage bar
        coverage_width = 200  # Width of the coverage bar in pixels
        covered_width = int(coverage_width * (total_coverage / 100))
        uncovered_width = coverage_width - covered_width
        
        lines.append("<td>")
        lines.append(f"<span style='display:inline-block;width:{covered_width}px;height:12px;background-color:#28a745'></span>")
        lines.append(f"<span style='display:inline-block;width:{uncovered_width}px;height:12px;background-color:#dc3545'></span>")
        lines.append("</td>")
        
        lines.append(f"<td>{total_coverage:.2f}%</td>")
        lines.append(f"<td>{total_covered}</td>")
        lines.append(f"<td>{total_executable}</td>")
        lines.append("</tr>")
        
        # Per-target coverage
        if 'targets' in code_coverage:
            sorted_targets = sorted(code_coverage['targets'], key=lambda t: t.get('name', '').lower())
            
            for target in sorted_targets:
                name = target.get('name', 'Unknown')
                coverage = target.get('lineCoverage', 0) * 100
                covered = target.get('coveredLines', 0)
                executable = target.get('executableLines', 0)
                
                # Skip targets with no executable lines
                if executable == 0:
                    continue
                
                lines.append("<tr>")
                lines.append(f"<td>{name}</td>")
                
                # Coverage bar
                covered_width = int(coverage_width * (coverage / 100))
                uncovered_width = coverage_width - covered_width
                
                lines.append("<td>")
                lines.append(f"<span style='display:inline-block;width:{covered_width}px;height:12px;background-color:#28a745'></span>")
                lines.append(f"<span style='display:inline-block;width:{uncovered_width}px;height:12px;background-color:#dc3545'></span>")
                lines.append("</td>")
                
                lines.append(f"<td>{coverage:.2f}%</td>")
                lines.append(f"<td>{covered}</td>")
                lines.append(f"<td>{executable}</td>")
                lines.append("</tr>")
                
                # File-level coverage for this target
                if 'files' in target:
                    sorted_files = sorted(target['files'], key=lambda f: f.get('name', '').lower())
                    
                    for file in sorted_files:
                        file_name = file.get('name', 'Unknown')
                        file_path = file.get('path', '')
                        file_coverage = file.get('lineCoverage', 0) * 100
                        file_covered = file.get('coveredLines', 0)
                        file_executable = file.get('executableLines', 0)
                        
                        # Skip files with no executable lines
                        if file_executable == 0:
                            continue
                        
                        lines.append("<tr>")
                        lines.append(f"<td>&nbsp;&nbsp;<a href=\"{file_path}\">{file_name}</a></td>")
                        
                        # Coverage bar for file
                        covered_width = int(coverage_width * (file_coverage / 100))
                        uncovered_width = coverage_width - covered_width
                        
                        lines.append("<td>")
                        lines.append(f"<span style='display:inline-block;width:{covered_width}px;height:12px;background-color:#28a745'></span>")
                        lines.append(f"<span style='display:inline-block;width:{uncovered_width}px;height:12px;background-color:#dc3545'></span>")
                        lines.append("</td>")
                        
                        lines.append(f"<td>{file_coverage:.2f}%</td>")
                        lines.append(f"<td>{file_covered}</td>")
                        lines.append(f"<td>{file_executable}</td>")
                        lines.append("</tr>")
        
        lines.append("</table>")
        
        return "\n".join(lines)

    def _determine_test_status(self, report):
        """Determine the overall test status"""
        # Check if any test failed
        for chapter in report['chapters']:
            for section_name, section in chapter['sections'].items():
                for test in section['details']:
                    if isinstance(test, dict) and test.get('testStatus') == 'Failure':
                        return 'failure'
        
        # If we have tests and none failed, it's a success
        has_tests = False
        for chapter in report['chapters']:
            if chapter['sections']:
                has_tests = True
                break
                
        return 'success' if has_tests else 'neutral'


class XCResultProcessor:
    def __init__(self, xcresult_path, debug=False, test_stats=None):
        self.xcresult_path = xcresult_path
        self.debug = debug
        self.show_passed_tests = True
        self.show_code_coverage = True
        self.test_stats = test_stats
        
        # Verify the xcresult bundle exists
        if not os.path.exists(xcresult_path):
            raise FileNotFoundError(f"The xcresult bundle at {xcresult_path} does not exist")
        
        # Verify it's a valid xcresult bundle
        if not xcresult_path.endswith('.xcresult') or not os.path.isdir(xcresult_path):
            raise ValueError(f"Not a valid xcresult bundle: {xcresult_path}")
        
        # Check Xcode version - required to be 16 or higher
        try:
            xcodebuild_output = subprocess.check_output(['xcodebuild', '-version'], universal_newlines=True)
            xcode_version_match = re.search(r'Xcode (\d+)\.(\d+)', xcodebuild_output)
            
            if xcode_version_match:
                major_version = int(xcode_version_match.group(1))
                if major_version < 16:
                    print(f"Detected Xcode version: {xcodebuild_output.strip()}")
                    raise ValueError("This script requires Xcode 16 or higher to function properly")
                
                if self.debug:
                    print(f"Detected Xcode version: {xcodebuild_output.strip()}")
                    print("Using Xcode 16+ command format")
            else:
                raise ValueError("Could not determine Xcode version from output")
                
        except (subprocess.SubprocessError, FileNotFoundError) as e:
            raise ValueError(f"Failed to detect Xcode version: {str(e)}")

    def generate_test_report(self):
        """Generate test report HTML without code coverage"""
        formatter = Formatter(self.xcresult_path, self.test_stats)
        
        report = formatter.format({
            'showPassedTests': self.show_passed_tests,
            'showCodeCoverage': self.show_code_coverage
        })
        
        # Combine test report parts
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xcode Test Results</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }}
        h1, h2, h3, h4 {{
            margin-top: 1.5em;
            margin-bottom: 0.5em;
        }}
        pre {{
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            overflow: auto;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }}
        .success {{
            color: #28a745;
        }}
        .failure {{
            color: #dc3545;
        }}
        table {{
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }}
        th, td {{
            text-align: left;
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #f5f5f5;
        }}
        tr:hover {{
            background-color: #f5f5f5;
        }}
        ul {{
            list-style-type: none;
            padding-left: 20px;
        }}
        code {{
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }}
    </style>
</head>
<body>
    <h1>Xcode Test Results</h1>
    <p>Results from {self.xcresult_path}</p>
    
    {report['reportSummary']}
    
    {report['reportDetail']}
</body>
</html>
"""
        return html

    def generate_coverage_report(self):
        """Generate code coverage HTML report"""
        formatter = Formatter(self.xcresult_path, self.test_stats)
        
        report = formatter.format({
            'showPassedTests': self.show_passed_tests,
            'showCodeCoverage': self.show_code_coverage
        })
        
        # Skip if no code coverage data
        if not report['codeCoverage']:
            return None
            
        # Create coverage report
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Coverage Results</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }}
        h1, h2, h3, h4 {{
            margin-top: 1.5em;
            margin-bottom: 0.5em;
        }}
        pre {{
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            overflow: auto;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }}
        .success {{
            color: #28a745;
        }}
        .failure {{
            color: #dc3545;
        }}
        table {{
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }}
        th, td {{
            text-align: left;
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #f5f5f5;
        }}
        tr:hover {{
            background-color: #f5f5f5;
        }}
        ul {{
            list-style-type: none;
            padding-left: 20px;
        }}
        code {{
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }}
    </style>
</head>
<body>
    <h1>Code Coverage Results</h1>
    <p>Coverage for {self.xcresult_path}</p>
    
    {report['codeCoverage']}
</body>
</html>
"""
        return html

    def generate_html_report(self):
        """Generate a complete HTML report (for backward compatibility)"""
        formatter = Formatter(self.xcresult_path, self.test_stats)
        
        report = formatter.format({
            'showPassedTests': self.show_passed_tests,
            'showCodeCoverage': self.show_code_coverage
        })
        
        # Combine all parts of the report
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xcode Test Results</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }}
        h1, h2, h3, h4 {{
            margin-top: 1.5em;
            margin-bottom: 0.5em;
        }}
        pre {{
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            overflow: auto;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }}
        .success {{
            color: #28a745;
        }}
        .failure {{
            color: #dc3545;
        }}
        table {{
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }}
        th, td {{
            text-align: left;
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #f5f5f5;
        }}
        tr:hover {{
            background-color: #f5f5f5;
        }}
        ul {{
            list-style-type: none;
            padding-left: 20px;
        }}
        code {{
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }}
    </style>
</head>
<body>
    <h1>Xcode Test Results</h1>
    <p>Results from {self.xcresult_path}</p>
    
    {report['reportSummary']}
    
    {report['reportDetail']}
    
    {report['codeCoverage']}
</body>
</html>
"""
        return html


def generate_summary_json(xcresult_path, output_path):
    """Generate JSON summary of test results"""
    try:
        print(f"Extracting test summary from {xcresult_path}")
        
        # Use xcrun xcresulttool directly to get test summary
        result = subprocess.run(
            ['xcrun', 'xcresulttool', 'get', '--legacy', '--format', 'json', '--path', xcresult_path],
            capture_output=True, text=True, check=True
        )
        
        # Parse the JSON output
        xcresult_json = json.loads(result.stdout)
        
        # Initialize counters
        passed_tests = 0
        failed_tests = 0
        skipped_tests = 0
        
        # Extract test counts from actions (test runs)
        if 'actions' in xcresult_json:
            for action in xcresult_json.get('actions', {}).get('_values', []):
                if 'actionResult' in action and 'testsRef' in action['actionResult']:
                    # Get the ID of the test summaries
                    test_ref_id = action['actionResult']['testsRef']['id']['_value']
                    
                    # Get detailed test results using the ID
                    test_result = subprocess.run(
                        ['xcrun', 'xcresulttool', 'get', '--legacy', '--format', 'json', '--path', xcresult_path, '--id', test_ref_id],
                        capture_output=True, text=True, check=True
                    )
                    test_json = json.loads(test_result.stdout)
                    
                    # Process summaries to get test counts
                    if 'summaries' in test_json:
                        for summary in test_json['summaries'].get('_values', []):
                            if 'testableSummaries' in summary:
                                for testable in summary['testableSummaries'].get('_values', []):
                                    # Extract test counts from testable summaries
                                    if 'tests' in testable:
                                        # Count tests recursively
                                        counts = count_tests_recursively(testable['tests'])
                                        passed_tests += counts['passed']
                                        failed_tests += counts['failed']
                                        skipped_tests += counts['skipped']
        
        # Fallback: try to extract from the summary directly
        if passed_tests == 0 and failed_tests == 0:
            # Try to find summary directly in the action results
            for action in xcresult_json.get('actions', {}).get('_values', []):
                if 'actionResult' in action:
                    result = action['actionResult']
                    if 'summaryRef' in result:
                        summary_id = result['summaryRef']['id']['_value']
                        summary_result = subprocess.run(
                            ['xcrun', 'xcresulttool', 'get', '--legacy', '--format', 'json', '--path', xcresult_path, '--id', summary_id],
                            capture_output=True, text=True, check=True
                        )
                        summary_json = json.loads(summary_result.stdout)
                        
                        if 'totals' in summary_json:
                            failed_tests = summary_json['totals'].get('failedCount', {}).get('_value', 0)
                            skipped_tests = summary_json['totals'].get('skippedCount', {}).get('_value', 0)
                            passed_tests = summary_json['totals'].get('testsCount', {}).get('_value', 0) - failed_tests - skipped_tests
        
        # Total includes all tests (passed, failed, and skipped)
        total_tests = passed_tests + failed_tests + skipped_tests
        
        # Calculate success rate (excluding skipped tests)
        success_rate = 0
        denominator = passed_tests + failed_tests
        if denominator > 0:
            success_rate = (passed_tests / denominator) * 100
        
        # Create summary JSON
        summary = {
            'total_tests': total_tests,
            'passed_tests': passed_tests,
            'failed_tests': failed_tests,
            'skipped_tests': skipped_tests,
            'success_rate': round(success_rate, 1)
        }
        
        print(f"Final test summary: {summary}")
        
        # Write to file
        with open(output_path, 'w') as f:
            json.dump(summary, f)
        
        return summary
    except Exception as e:
        print(f"Error generating summary JSON: {str(e)}")
        traceback.print_exc()
        return None

def count_tests_recursively(tests_array):
    """Count tests recursively from the test hierarchy"""
    counts = {'total': 0, 'passed': 0, 'failed': 0, 'skipped': 0}
    
    if not tests_array or '_values' not in tests_array:
        return counts
    
    for test in tests_array.get('_values', []):
        # If this is a test group with subtests, process them recursively
        if 'subtests' in test:
            sub_counts = count_tests_recursively(test['subtests'])
            counts['passed'] += sub_counts['passed']
            counts['failed'] += sub_counts['failed']
            counts['skipped'] += sub_counts['skipped']
            counts['total'] += sub_counts['passed'] + sub_counts['failed'] + sub_counts['skipped']
        else:
            # This is an actual test case
            # Get test status
            test_status = None
            if 'testStatus' in test:
                test_status = test['testStatus'].get('_value', '')
            
            if test_status == 'Success':
                counts['passed'] += 1
                counts['total'] += 1
            elif test_status == 'Failure':
                counts['failed'] += 1
                counts['total'] += 1
            elif test_status == 'Skipped' or test_status == 'Expected Failure':
                # Count both skipped and expected failures as skipped tests
                counts['skipped'] += 1
                counts['total'] += 1  # Skipped tests count in the total
    
    return counts

def main():
    parser = argparse.ArgumentParser(description='Process Xcode test results')
    parser.add_argument('--path', required=True, help='Path to .xcresult bundle')
    parser.add_argument('--output', required=False, help='Path to output HTML report (combined report, for backward compatibility)')
    parser.add_argument('--test-output', required=False, help='Path to output test report HTML')
    parser.add_argument('--coverage-output', required=False, help='Path to output code coverage HTML')
    parser.add_argument('--open', action='store_true', help='Open the report in a web browser after generation')
    parser.add_argument('--open-in-browser', action='store_true', help='Open the report in a web browser after generation')
    parser.add_argument('--summary-json', help='Path to output summary statistics as JSON')
    parser.add_argument('--debug', action='store_true', help='Show debug information')
    
    args = parser.parse_args()
    
    try:
        # First, generate the JSON summary to ensure we have accurate test counts
        test_stats = None
        if args.summary_json:
            test_stats = generate_summary_json(args.path, args.summary_json)
        
        # Create processor with test stats if available
        processor = XCResultProcessor(
            args.path, 
            debug=args.debug,
            test_stats=test_stats
        )
        
        # Always show passed tests and code coverage
        processor.show_passed_tests = True
        processor.show_code_coverage = True
        
        # Determine which reports to generate
        generate_combined = args.output is not None
        generate_test = args.test_output is not None
        generate_coverage = args.coverage_output is not None
        
        # If no specific outputs are requested, default to combined report
        if not generate_combined and not generate_test and not generate_coverage:
            print("No output paths specified. Please specify at least one of --output, --test-output, or --coverage-output")
            sys.exit(1)
        
        # Generate combined report if requested (backward compatibility)
        if generate_combined:
            html_report = processor.generate_html_report()
            output_path = os.path.abspath(args.output)
            
            with open(output_path, 'w') as f:
                f.write(html_report)
            
            print(f"Combined report successfully generated and saved to {output_path}")
            
            # Open in browser if requested
            if args.open or args.open_in_browser:
                webbrowser.open('file://' + output_path)
                print(f"Opening combined report in default web browser...")
        
        # Generate test report if requested
        if generate_test:
            test_report = processor.generate_test_report()
            test_output_path = os.path.abspath(args.test_output)
            
            with open(test_output_path, 'w') as f:
                f.write(test_report)
            
            print(f"Test report successfully generated and saved to {test_output_path}")
            
            # Open in browser if requested and combined report wasn't opened
            if (args.open or args.open_in_browser) and not generate_combined:
                webbrowser.open('file://' + test_output_path)
                print(f"Opening test report in default web browser...")
        
        # Generate coverage report if requested
        if generate_coverage:
            coverage_report = processor.generate_coverage_report()
            if coverage_report:
                coverage_output_path = os.path.abspath(args.coverage_output)
                
                with open(coverage_output_path, 'w') as f:
                    f.write(coverage_report)
                
                print(f"Coverage report successfully generated and saved to {coverage_output_path}")
                
                # Open in browser if requested and no other reports were opened
                if (args.open or args.open_in_browser) and not generate_combined and not generate_test:
                    webbrowser.open('file://' + coverage_output_path)
                    print(f"Opening coverage report in default web browser...")
            else:
                print("No code coverage data found. Coverage report not generated.")
        
    except Exception as e:
        print(f"Error: {str(e)}")
        if args.debug:
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main() 