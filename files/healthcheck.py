#!/usr/bin/env python3
"""
Simple HTTP health check server for Aska dedicated server.
Responds to /health endpoint and checks if the game server process is running.
"""

import http.server
import socketserver
import subprocess
import sys
from urllib.parse import urlparse

PORT = 8080

class HealthCheckHandler(http.server.BaseHTTPRequestHandler):
    """HTTP handler for health check requests."""
    
    def log_message(self, format, *args):
        """Suppress default logging to reduce noise."""
        pass
    
    def is_server_running(self):
        """Check if the Aska server process is running."""
        try:
            # Check for AskaServer.exe process running under wine
            result = subprocess.run(
                ['pgrep', '-f', 'AskaServer.exe'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except Exception as e:
            print(f"Error checking server status: {e}", file=sys.stderr)
            return False
    
    def do_GET(self):
        """Handle GET requests."""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/health':
            # Check if server is running
            if self.is_server_running():
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"status":"healthy","server":"running"}\n')
            else:
                self.send_response(503)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"status":"unhealthy","server":"not running"}\n')
        else:
            # Return 404 for any other path
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error":"not found"}\n')

def main():
    """Start the health check HTTP server."""
    try:
        with socketserver.TCPServer(("", PORT), HealthCheckHandler) as httpd:
            print(f"Health check server running on port {PORT}")
            print(f"Health endpoint: http://localhost:{PORT}/health")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nHealth check server stopped")
        sys.exit(0)
    except Exception as e:
        print(f"Error starting health check server: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

