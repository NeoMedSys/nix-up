#!/usr/bin/env bash
# Camera Testing & Debug Script
# Add this to modules/system-packages.nix as a custom script

(pkgs.writeScriptBin "camera-debug" ''
  #!/bin/bash
  
  echo "=== Intel IPU6 Camera Debug ==="
  echo "Date: $(date)"
  echo ""
  
  echo "1. Checking IPU6 kernel modules:"
  lsmod | grep -E "(ipu6|intel_ipu6)" || echo "No IPU6 modules loaded"
  echo ""
  
  echo "2. Checking for camera devices:"
  ls -la /dev/video* 2>/dev/null || echo "No video devices found"
  echo ""
  
  echo "3. Checking dmesg for IPU6 messages:"
  dmesg | grep -i ipu6 | tail -10
  echo ""
  
  echo "4. Checking if cameras are detected:"
  v4l2-ctl --list-devices 2>/dev/null || echo "v4l2-utils not available or no devices"
  echo ""
  
  echo "5. Testing with libcamera:"
  libcamera-hello --list-cameras 2>/dev/null || echo "libcamera-hello not available or failed"
  echo ""
  
  echo "6. Checking PipeWire camera access:"
  pw-cli ls Node | grep -A5 -i camera || echo "No camera nodes in PipeWire"
  echo ""
  
  echo "7. Testing camera with GStreamer:"
  echo "Attempting 5-second camera test..."
  timeout 5s gst-launch-1.0 icamerasrc ! videoconvert ! xvimagesink 2>/dev/null || \
  timeout 5s gst-launch-1.0 v4l2src ! videoconvert ! xvimagesink 2>/dev/null || \
  echo "Camera test failed - no working camera source found"
  echo ""
  
  echo "8. Checking secure mode status:"
  dmesg | grep -i "secure mode" | tail -5
  echo ""
  
  echo "9. Portal status:"
  systemctl --user status xdg-desktop-portal-gtk
  echo ""
  
  echo "=== Debug complete ==="
  echo "If cameras still don't work:"
  echo "1. Try: sudo modprobe -r intel_ipu6_isys && sudo modprobe intel_ipu6_isys"
  echo "2. Check BIOS settings - disable camera privacy mode if present"
  echo "3. Try updating firmware: fwupdmgr update"
'')
