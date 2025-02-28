#!/bin/bash
set -e

# Configuration
APP_NAME="dartotsu"
APP_VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2)

# Create AppDir structure
mkdir -p AppDir/usr/{bin,lib,share/applications,share/icons/hicolor/scalable/apps}

# Build Dart application for Linux
echo "Building Dart application..."
flutter build linux --release

# Copy build artifacts to AppDir
echo "Copying build artifacts to AppDir..."
cp -r build/linux/*/release/bundle/* AppDir/usr/bin/

# Create .desktop file
cat > AppDir/usr/share/applications/$APP_NAME.desktop << EOF
[Desktop Entry]
Name=Dartotsu
Exec=dartotsu
Icon=dartotsu
Type=Application
Categories=Utility;
EOF

# Copy icon (assuming there is an icon file in the assets directory)
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps/
cp assets/images/logo.png AppDir/usr/share/icons/hicolor/256x256/apps/dartotsu.png


# Create AppRun file (the entry point for the AppImage)
cat > AppDir/AppRun << EOF
#!/bin/bash
SELF=\$(readlink -f "\$0")
HERE=\${SELF%/*}
export PATH="\${HERE}/usr/bin:\${PATH}"
export LD_LIBRARY_PATH="\${HERE}/usr/lib:\${LD_LIBRARY_PATH}"
exec "\${HERE}/usr/bin/dartotsu" "\$@"
EOF
chmod +x AppDir/AppRun

# Download appimagetool if not present
if [ ! -f appimagetool-x86_64.AppImage ]; then
  echo "Downloading appimagetool..."
  wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x appimagetool-x86_64.AppImage
fi

# Generate AppImage
echo "Generating AppImage..."
ARCH=x86_64 ./appimagetool-x86_64.AppImage AppDir "${APP_NAME}-${APP_VERSION}-${ARCH}.AppImage"

echo "AppImage created: ${APP_NAME}-${APP_VERSION}-${ARCH}.AppImage"
