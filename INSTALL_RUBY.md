# Installing Ruby on Windows

## Quick Installation Guide

### Option 1: RubyInstaller (Recommended for Windows)

1. **Download RubyInstaller:**
   - Go to: https://rubyinstaller.org/downloads/
   - Download **Ruby+Devkit 3.2.x** (latest stable version)
   - Choose the **x64** version for 64-bit Windows

2. **Run the Installer:**
   - Run the downloaded `.exe` file
   - **Important:** Check "Add Ruby executables to your PATH" during installation
   - Check "Associate .rb and .rbw files with this Ruby installation"
   - Click "Install"

3. **Complete Devkit Setup:**
   - After installation, a new terminal window will open
   - It will ask you to run `ridk install`
   - Type `3` and press Enter (to install MSYS2 and MINGW development toolchain)
   - Wait for it to complete

4. **Verify Installation:**
   ```powershell
   ruby --version
   gem --version
   ```

5. **Install Bundler:**
   ```powershell
   gem install bundler
   ```

### Option 2: Using Chocolatey (If you have it)

```powershell
choco install ruby
```

Then install bundler:
```powershell
gem install bundler
```

### Option 3: Using Scoop (If you have it)

```powershell
scoop install ruby
```

Then install bundler:
```powershell
gem install bundler
```

## After Installation

1. **Close and reopen your terminal** (or restart PowerShell) to refresh PATH

2. **Verify everything works:**
   ```powershell
   ruby --version
   gem --version
   bundle --version
   ```

3. **Navigate to your project:**
   ```powershell
   cd "F:\tictok scraping"
   ```

4. **Install dependencies:**
   ```powershell
   bundle install
   ```

## Troubleshooting

### "ruby is not recognized"
- Make sure you checked "Add Ruby executables to your PATH" during installation
- Restart your terminal/PowerShell
- Or manually add Ruby to PATH:
  - Find Ruby installation folder (usually `C:\Ruby32-x64` or `C:\Ruby33-x64`)
  - Add `C:\Ruby32-x64\bin` to your system PATH

### "bundle is not recognized"
- Install bundler: `gem install bundler`
- Restart terminal

### SSL Certificate Errors
If you get SSL errors when installing gems:
```powershell
gem sources --add https://rubygems.org/ --remove https://rubygems.org/
```

## Next Steps After Ruby is Installed

1. Install Node.js dependencies: `npm install`
2. Install Ruby dependencies: `bundle install`
3. Set up MongoDB
4. Create TikTokShop record
5. Run the sync

