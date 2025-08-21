#!/usr/bin/env python3

"""
Direct APNs Push Notification Sender

A script to send push notifications directly to Apple Push Notification service (APNs)
using SSL certificates. Uses the apns2 library for robust APNs communication.

Usage:
    python test_push.py --token <device_token> --message <message> --cert <cert_path> [options]

Requirements:
    pip install apns2
"""

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Optional, Dict, Any

try:
    import httpx
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.serialization import pkcs12
    import ssl
    import tempfile
except ImportError as e:
    missing = str(e).split("'")[1] if "'" in str(e) else str(e)
    print(f"❌ Error: {missing} not installed. Run: pip install 'httpx[http2]==0.24.1' cryptography 'h2==4.1.0'")
    sys.exit(1)


class APNsPushSender:
    """Direct APNs push notification sender using httpx with certificate authentication."""
    
    # APNs endpoints
    PRODUCTION_URL = "https://api.push.apple.com:443"
    SANDBOX_URL = "https://api.sandbox.push.apple.com:443"
    
    def __init__(self, cert_path: str, sandbox: bool = True, cert_password: str = None):
        """
        Initialize APNs client.
        
        Args:
            cert_path: Path to .pem or .p12 certificate file
            sandbox: Use sandbox environment (default: True)
            cert_password: Password for P12 certificate (None for no password)
        """
        self.cert_path = Path(cert_path)
        self.sandbox = sandbox
        self.environment = "sandbox" if sandbox else "production"
        self.base_url = self.SANDBOX_URL if sandbox else self.PRODUCTION_URL
        self.cert_password = cert_password
        
        if not self.cert_path.exists():
            raise FileNotFoundError(f"Certificate file not found: {cert_path}")
        
        # Prepare certificate - store temp files for P12
        self.temp_cert_file = None
        self.temp_key_file = None
        if self.cert_path.suffix.lower() == '.p12':
            self._prepare_p12_certificate()
        print(f"✅ APNs client initialized for {self.environment}")
    
    def _prepare_p12_certificate(self):
        """Prepare P12 certificate by converting to temporary PEM files."""
        try:
            # Handle P12 certificate - convert to PEM
            # Use provided password or assume no password
            if self.cert_password is not None:
                password = self.cert_password.encode() if self.cert_password else None
            else:
                password = None  # Assume no password if not provided
            
            # Load P12 file
            with open(self.cert_path, 'rb') as f:
                p12_data = f.read()
            
            private_key, certificate, additional_certificates = pkcs12.load_key_and_certificates(
                p12_data, password
            )
            
            # Create temporary PEM files
            cert_file = tempfile.NamedTemporaryFile(mode='w', suffix='.pem', delete=False)
            key_file = tempfile.NamedTemporaryFile(mode='w', suffix='.pem', delete=False)
            
            # Write certificate
            cert_pem = certificate.public_bytes(serialization.Encoding.PEM).decode()
            cert_file.write(cert_pem)
            cert_file.close()
            
            # Write private key
            key_pem = private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ).decode()
            key_file.write(key_pem)
            key_file.close()
            
            # Store temp file paths
            self.temp_cert_file = cert_file.name
            self.temp_key_file = key_file.name
            
        except Exception as e:
            raise Exception(f"Failed to prepare P12 certificate: {e}")
    
    def _get_temp_pem_files(self):
        """Get temporary PEM file paths for P12 certificates."""
        return self.temp_cert_file, self.temp_key_file
    
    def __del__(self):
        """Clean up temporary files."""
        if self.temp_cert_file and Path(self.temp_cert_file).exists():
            try:
                Path(self.temp_cert_file).unlink()
            except:
                pass
        if self.temp_key_file and Path(self.temp_key_file).exists():
            try:
                Path(self.temp_key_file).unlink()
            except:
                pass
    
    def create_payload(self, message: str, title: str = "Test Push", 
                      badge: Optional[int] = None, sound: str = "default",
                      custom_data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Create APNs payload dictionary.
        
        Args:
            message: Alert message body
            title: Alert title
            badge: App badge number
            sound: Sound file name
            custom_data: Additional custom data
            
        Returns:
            APNs payload dictionary
        """
        payload = {
            "aps": {
                "alert": {
                    "title": title,
                    "body": message
                },
                "sound": sound
            }
        }
        
        if badge is not None:
            payload["aps"]["badge"] = badge
            
        if custom_data:
            payload.update(custom_data)
            
        return payload
    
    def send_push(self, device_token: str, payload: Dict[str, Any], 
                  bundle_id: str = "com.sumeru.IterableSDK-Integration-Tester",
                  priority: int = 10, expiration: Optional[int] = None) -> bool:
        """
        Send push notification to device.
        
        Args:
            device_token: Device token (64, 128, or 160 hex characters)
            payload: APNs payload dictionary
            bundle_id: App bundle identifier
            priority: Notification priority (5=low, 10=high)
            expiration: Expiration timestamp (None=no expiration)
            
        Returns:
            True if successful, False otherwise
        """
        # Validate device token
        if not self._validate_device_token(device_token):
            return False
        
        # Prepare headers
        headers = {
            "apns-topic": bundle_id,
            "apns-priority": str(priority),
            "content-type": "application/json"
        }
        
        if expiration:
            headers["apns-expiration"] = str(expiration)
        
        # Generate unique message ID (UUID format works best with APNs)
        import uuid
        apns_id = str(uuid.uuid4())
        headers["apns-id"] = apns_id
        
        url = f"{self.base_url}/3/device/{device_token}"
        
        try:
            print(f"🚀 Sending push to {self.environment} APNs...")
            print(f"📱 Device Token: {device_token[:8]}...{device_token[-8:]}")
            print(f"📦 Bundle ID: {bundle_id}")
            
            # Extract message for display
            if "aps" in payload and "alert" in payload["aps"]:
                alert = payload["aps"]["alert"]
                if isinstance(alert, dict):
                    message = alert.get("body", "N/A")
                else:
                    message = str(alert)
            else:
                message = "Silent push"
            print(f"💬 Message: {message}")
            print(f"🆔 APNs ID: {apns_id}")
            
            # Send HTTPS request with client certificate
            # Use the certificate files directly (convert P12 to temp PEM if needed)
            if self.cert_path.suffix.lower() == '.p12':
                cert_file, key_file = self._get_temp_pem_files()
                cert = (cert_file, key_file)
            else:
                cert = str(self.cert_path)
            
            with httpx.Client(cert=cert, http2=True, timeout=30.0, verify=True) as client:
                response = client.post(
                    url,
                    headers=headers,
                    json=payload
                )
            
            return self._handle_response(response, apns_id)
                
        except Exception as e:
            print(f"❌ Error sending push: {e}")
            return False
    
    def _validate_device_token(self, token: str) -> bool:
        """Validate device token format."""
        # iOS device tokens: 32 bytes (64 hex), 64 bytes (128 hex), or 80 bytes (160 hex)
        if len(token) not in [64, 128, 160]:
            print(f"❌ Invalid token length: {len(token)} (expected 64, 128, or 160 characters)")
            return False
            
        try:
            int(token, 16)  # Check if valid hex
        except ValueError:
            print("❌ Invalid token format: not hexadecimal")
            return False
            
        return True
    
    def _handle_response(self, response: httpx.Response, apns_id: str) -> bool:
        """Handle APNs response."""
        if response.status_code == 200:
            print(f"✅ Push sent successfully!")
            print(f"📋 Status: {response.status_code}")
            return True
        else:
            print(f"❌ Push failed!")
            print(f"📋 Status: {response.status_code}")
            print(f"🔍 APNs ID: {apns_id}")
            
            try:
                error_data = response.json()
                print(f"📄 Error: {error_data.get('reason', 'Unknown error')}")
                if 'timestamp' in error_data:
                    print(f"⏰ Timestamp: {error_data['timestamp']}")
            except:
                print(f"📄 Response: {response.text}")
                
            return False



def prompt_for_missing_args(args):
    """Prompt user for missing required arguments."""
    
    if args.interactive:
        print("🔧 Interactive mode - configuring push notification...")
        print()
    
    # Prompt for device token if not provided
    if not args.token:
        if args.interactive:
            print("📱 Device Token Configuration")
        else:
            print("📱 Device token is required")
        while True:
            token = input("Enter device token (64, 128, or 160 hex characters): ").strip()
            if len(token) in [64, 128, 160]:
                try:
                    int(token, 16)  # Validate hex
                    args.token = token
                    break
                except ValueError:
                    print("❌ Invalid format: must be hexadecimal")
            else:
                print(f"❌ Invalid length: {len(token)} (expected 64, 128, or 160 characters)")
        if args.interactive:
            print("✅ Device token configured")
            print()
    
    # Prompt for certificate path if not provided
    if not args.cert:
        if args.interactive:
            print("🔐 Certificate Configuration")
        else:
            print("🔐 Certificate file is required")
        while True:
            cert_path = input("Enter path to APNs certificate (.pem or .p12 file): ").strip()
            if cert_path:
                # Expand ~ to home directory
                expanded_path = Path(cert_path).expanduser()
                if expanded_path.exists():
                    args.cert = str(expanded_path)
                    break
                else:
                    print(f"❌ File not found: {expanded_path}")
            else:
                print("❌ Please enter a valid path")
        if args.interactive:
            print("✅ Certificate configured")
            print()
    
    # Interactive mode: ask about environment
    if args.interactive and not hasattr(args, '_env_prompted'):
        choice = input("Use production environment? [y/N]: ").strip().lower()
        args.production = choice in ['y', 'yes']
        print(f"✅ Environment: {'Production' if args.production else 'Sandbox'}")
        print()
        args._env_prompted = True
    
    # Interactive mode: ask about silent push
    if args.interactive and not hasattr(args, '_silent_prompted'):
        choice = input("Send silent push? [y/N]: ").strip().lower()
        args.silent = choice in ['y', 'yes']
        if args.silent:
            print("✅ Silent push configured")
            print()
        args._silent_prompted = True
    
    # Prompt for message if not provided and not silent
    if not args.silent and not args.message:
        if args.interactive:
            print("💬 Message Configuration")
        else:
            print("💬 Message is required for non-silent push")
        while True:
            message = input("Enter push notification message: ").strip()
            if message:
                args.message = message
                break
            else:
                print("❌ Message cannot be empty")
        if args.interactive:
            print("✅ Message configured")
            print()
    
    # Interactive mode: optional configurations
    if args.interactive:
        if not args.title or args.title == "Test Push":
            title = input(f"Enter title [default: 'Test Push']: ").strip()
            if title:
                args.title = title
        
        if not args.badge:
            badge_input = input("Enter badge number [optional]: ").strip()
            if badge_input.isdigit():
                args.badge = int(badge_input)
        
        print("🚀 Configuration complete! Sending push notification...")
        print()


def main():
    """Main script entry point."""
    parser = argparse.ArgumentParser(
        description="Send push notifications directly to APNs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic push
  python test_push.py --token abc123... --message "Hello World!" --cert push_cert.pem
  
  # Production push with custom title
  python test_push.py --token abc123... --message "Production test" --cert prod_cert.pem --production --title "Prod Alert"
  
  # Silent push
  python test_push.py --token abc123... --cert push_cert.pem --silent
        """
    )
    
    # Required arguments (but we'll prompt if missing)
    parser.add_argument(
        "--token", 
        help="Device token (64, 128, or 160 hex characters)"
    )
    parser.add_argument(
        "--cert", 
        help="Path to APNs certificate (.pem or .p12 file)"
    )
    parser.add_argument(
        "--cert-password",
        help="Password for P12 certificate (optional)"
    )
    
    # Message arguments
    parser.add_argument(
        "--message",
        help="Push notification message body"
    )
    parser.add_argument(
        "--title",
        default="Test Push",
        help="Push notification title (default: 'Test Push')"
    )
    
    # Optional arguments
    parser.add_argument(
        "--bundle-id",
        default="com.sumeru.IterableSDK-Integration-Tester",
        help="App bundle identifier"
    )
    parser.add_argument(
        "--production",
        action="store_true",
        help="Use production APNs (default: sandbox)"
    )
    parser.add_argument(
        "--silent",
        action="store_true",
        help="Send silent push (content-available)"
    )
    parser.add_argument(
        "--badge",
        type=int,
        help="App badge number"
    )
    parser.add_argument(
        "--sound",
        default="default",
        help="Sound file name (default: 'default')"
    )
    parser.add_argument(
        "--priority",
        type=int,
        choices=[5, 10],
        default=10,
        help="Push priority: 5=low, 10=high (default: 10)"
    )
    parser.add_argument(
        "--custom-data",
        help="Custom JSON data to include in payload"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Verbose output"
    )
    parser.add_argument(
        "--interactive", "-i",
        action="store_true",
        help="Run in interactive mode (prompt for all arguments)"
    )
    
    args = parser.parse_args()
    
    # Prompt for missing required arguments
    prompt_for_missing_args(args)
    
    # Parse custom data
    custom_data = None
    if args.custom_data:
        try:
            custom_data = json.loads(args.custom_data)
        except json.JSONDecodeError as e:
            print(f"❌ Error: Invalid JSON in --custom-data: {e}")
            sys.exit(1)
    
    try:
        # Create APNs client
        sender = APNsPushSender(
            cert_path=args.cert,
            sandbox=not args.production,
            cert_password=args.cert_password
        )
        
        # Create payload
        if args.silent:
            payload = {
                "aps": {
                    "content-available": 1
                }
            }
            if custom_data:
                payload.update(custom_data)
        else:
            payload = sender.create_payload(
                message=args.message,
                title=args.title,
                badge=args.badge,
                sound=args.sound,
                custom_data=custom_data
            )
        
        if args.verbose:
            print(f"📋 Payload: {json.dumps(payload, indent=2)}")
        
        # Send push
        success = sender.send_push(
            device_token=args.token,
            payload=payload,
            bundle_id=args.bundle_id,
            priority=args.priority
        )
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
