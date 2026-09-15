#!/usr/bin/env python3
"""Emit only Super via a temporary uinput keyboard to exercise keyd -> XKB -> IPC."""
import fcntl
import json
import os
import struct
import subprocess
import time

base=['quickshell','ipc','-p','/home/ry/.config/quickshell','call','expander']
def ipc(*args): return subprocess.check_output(base+list(args),text=True).strip()
def status(): return json.loads(ipc('status'))
fd=os.open('/dev/uinput',os.O_WRONLY|os.O_NONBLOCK)
created=False
try:
 fcntl.ioctl(fd,0x40045564,1) # UI_SET_EVBIT EV_KEY
 # A complete keyboard capability map lets keyd identify it as a keyboard.
 for key in range(1,249): fcntl.ioctl(fd,0x40045565,key)
 setup=struct.pack('80sHHHHI',b'Expander Gesture Test',3,0x1234,0x5678,1,0)+bytes(64*4*4)
 os.write(fd,setup); fcntl.ioctl(fd,0x5501); created=True
 time.sleep(1)
 def event(code,value):
  os.write(fd,struct.pack('llHHi',0,0,1,code,value))
  os.write(fd,struct.pack('llHHi',0,0,0,0,0))
 def gesture(duration):
  event(125,1); time.sleep(duration); event(125,0); time.sleep(.6)
 ipc('hide')
 gesture(.1); assert status()['visible'] and status()['tab']==0,status()
 gesture(.1); assert status()['visible'] and status()['tab']==1,status()
 ipc('hide')
 gesture(.7); assert status()['power'],status()
 print('PASS live keyd -> XKB -> Hyprland -> Quickshell: tap, re-tap, hold/release')
finally:
 if created:
  event(125,0)
  fcntl.ioctl(fd,0x5502)
 os.close(fd)
 ipc('hide')
