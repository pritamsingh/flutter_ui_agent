"""
Test script for Flutter UI Agent
Verifies installation and basic functionality
"""

import os
import sys

def check_dependencies():
    """Check if all required packages are installed"""
    print("🔍 Checking dependencies...\n")
    
    required_packages = [
        'langchain',
        'langchain_google_genai',
        'google.generativeai',
        'pydantic'
    ]
    
    missing = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✓ {package}")
        except ImportError:
            print(f"✗ {package} - MISSING")
            missing.append(package)
    
    if missing:
        print(f"\n❌ Missing packages: {', '.join(missing)}")
        print("Run: pip install -r requirements.txt")
        return False
    
    print("\n✅ All dependencies installed!")
    return True


def check_api_key():
    """Check if API key is configured"""
    print("\n🔍 Checking API key configuration...\n")
    
    api_key = os.getenv('GOOGLE_API_KEY')
    
    if api_key:
        masked_key = api_key[:8] + '...' + api_key[-4:] if len(api_key) > 12 else '***'
        print(f"✓ API key found: {masked_key}")
        return True
    else:
        print("✗ GOOGLE_API_KEY not found in environment")
        print("\nSet it with:")
        print("  export GOOGLE_API_KEY='your-key-here'")
        print("Or create a .env file")
        return False


def run_simple_test():
    """Run a simple generation test"""
    print("\n🔍 Running simple test...\n")
    
    try:
        from flutter_ui_agent import FlutterUIAgent
        
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            print("⚠️  Skipping test - no API key configured")
            return False
        
        print("Initializing agent...")
        agent = FlutterUIAgent(api_key)
        
        print("Generating simple UI...")
        schema = agent.generate_ui("A blue button that says Hello")
        
        print(f"✅ Generated schema with type: {schema.get('type')}")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False


def main():
    """Run all checks"""
    print("=" * 50)
    print("Flutter UI Agent - Setup Verification")
    print("=" * 50)
    
    deps_ok = check_dependencies()
    api_ok = check_api_key()
    
    if deps_ok and api_ok:
        print("\n" + "=" * 50)
        print("✅ Setup Complete!")
        print("=" * 50)
        print("\nYou're ready to use the Flutter UI Agent!")
        print("Run: python flutter_ui_agent.py")
    else:
        print("\n" + "=" * 50)
        print("⚠️  Setup Incomplete")
        print("=" * 50)
        print("\nPlease fix the issues above before continuing.")
        sys.exit(1)


if __name__ == "__main__":
    main()
