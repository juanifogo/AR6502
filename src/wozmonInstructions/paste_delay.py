import pyautogui
import time
import sys
import os

length = len(sys.argv)
if length == 0 or length > 6:
    print(" A Usage: python paste_delay.py [-CharDelaySec] [-LineDelaySec] <FilePath>")
    exit()
    
FilePath = sys.argv[-1]
CharDelaySec = [sys.argv[i+1] for i,x in enumerate(sys.argv) if x == "-CharDelaySec" or x == "-CDS"]
LineDelaySec = [sys.argv[i+1] for i,x in enumerate(sys.argv) if x == "-LineDelaySec" or x == "-LDS"]

if CharDelaySec == []:
    CharDelaySec = [0.005]
    
if LineDelaySec == []:
    LineDelaySec = [0.05]
    
if len(CharDelaySec) > 1 or len(LineDelaySec) > 1:
    print(" B Usage: python paste_delay.py [-CharDelaySec] [-LineDelaySec] <FilePath>")
    exit()
try:
    CharDelaySec = float(CharDelaySec[0])
    LineDelaySec = float(LineDelaySec[0])
except:
    print(" C Usage: python paste_delay.py [-CharDelay] [-LineDelay] <FilePath>")
    exit()

if(not os.path.isfile(FilePath)):
    print("ERROR: File not found")
    exit()

lines = []
with open(FilePath, "r") as f:
    lines = f.readlines()
    
if lines == []:
    print("ERROR: File is empty or not readable")
    exit()

time.sleep(3)
pyautogui.alert("Click para continuar")
for line in lines:
    pyautogui.write(line, interval=CharDelaySec)
    time.sleep(LineDelaySec)