"""B42-BEGIN-DOUBLE-CLICK probe helper: real X input through XTest (ctypes, libX11 and libXtst only) into the game window on an
Xvfb display, for game/tests/begin_click_x11_probe.gd (see its header). Usage: python3 -I tools/begin_click_xtest.py COORDS MODE."""
import ctypes, sys, time, json, os
X = ctypes.cdll.LoadLibrary("libX11.so.6"); T = ctypes.cdll.LoadLibrary("libXtst.so.6")
X.XOpenDisplay.restype = ctypes.c_void_p
X.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
X.XStringToKeysym.restype = ctypes.c_ulong; X.XStringToKeysym.argtypes = [ctypes.c_char_p]
X.XFlush.argtypes = [ctypes.c_void_p]
T.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
T.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
T.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
d = X.XOpenDisplay(None)
assert d, "no display"
coords = sys.argv[1]
while not os.path.exists(coords): time.sleep(0.2)
time.sleep(1.0)
c = json.load(open(coords))
def move(x, y):
    T.XTestFakeMotionEvent(d, -1, int(x), int(y), 0); X.XFlush(d); time.sleep(0.15)
def click(x, y):
    move(x - 6, y); move(x, y)
    T.XTestFakeButtonEvent(d, 1, 1, 0); X.XFlush(d); time.sleep(0.12)
    T.XTestFakeButtonEvent(d, 1, 0, 0); X.XFlush(d); time.sleep(0.3)
def key(name, shift=False):
    kc = X.XKeysymToKeycode(d, X.XStringToKeysym(name.encode()))
    sk = X.XKeysymToKeycode(d, X.XStringToKeysym(b"Shift_L"))
    if shift: T.XTestFakeKeyEvent(d, sk, 1, 0)
    T.XTestFakeKeyEvent(d, kc, 1, 0); X.XFlush(d); time.sleep(0.05)
    T.XTestFakeKeyEvent(d, kc, 0, 0)
    if shift: T.XTestFakeKeyEvent(d, sk, 0, 0)
    X.XFlush(d); time.sleep(0.1)
mode = sys.argv[2]
if "warm" in mode:
    click(c["begin"][0] - 400, c["begin"][1] - 300); time.sleep(0.5)
if "emptyfirst" in mode:
    click(*c["begin"]); time.sleep(0.5)
elif "kbd" in mode:
    pass
else:
    click(*c["name"])
key("a", True); key("d"); key("a")
if "enter" in mode:
    key("Return")
if "tab" in mode:
    key("Tab"); key("s", True); key("m"); key("i")
if "family" in mode:
    click(*c["family"]); key("s", True); key("m"); key("i")
if "fenter" in mode:
    key("Return")
if "wait" in mode:
    time.sleep(2.0)
if "fast" in mode:
    T.XTestFakeMotionEvent(d, -1, int(c["begin"][0]), int(c["begin"][1]), 0)
    T.XTestFakeButtonEvent(d, 1, 1, 0); T.XTestFakeButtonEvent(d, 1, 0, 0); X.XFlush(d)
elif "nomove" in mode:
    T.XTestFakeMotionEvent(d, -1, int(c["begin"][0]), int(c["begin"][1]), 0); X.XFlush(d); time.sleep(0.5)
    T.XTestFakeButtonEvent(d, 1, 1, 0); X.XFlush(d); T.XTestFakeButtonEvent(d, 1, 0, 0); X.XFlush(d)
else:
    click(*c["begin"])
print("xt: one click on Begin sent", flush=True)
