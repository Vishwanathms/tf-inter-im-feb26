# Create bin directory if it doesn't exist
mkdir -p ~/bin
cd ~

# Download latest release (this automatically gets the latest version)
curl -s https://api.github.com/repos/cli/cli/releases/latest \
  | grep "browser_download_url.*linux_amd64.tar.gz" \
  | cut -d '"' -f 4 \
  | wget -qi -

# Extract (the filename will match whatever was downloaded)
tar -xzf gh_*_linux_amd64.tar.gz

# Move binary to your bin directory
mv gh_*/bin/gh ~/bin/

# Clean up
rm -rf gh_*

# Add to PATH
export PATH="$HOME/bin:$PATH"

# Verify installation
gh --version