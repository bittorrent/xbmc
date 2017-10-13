##########################################
# NT (Windows) specific System functions
##########################################
import xbmc
import xbmcaddon
import os, sys
import subprocess
import traceback

__addon__ = xbmcaddon.Addon()
__addonname__ = __addon__.getAddonInfo('name')
__addonpath__ = __addon__.getAddonInfo('path')

def run(command) :
    xbmc.log('%s: run \"%s\"' % (__addonname__, ' '.join(command)), xbmc.LOGDEBUG)
    try:
        process = subprocess.Popen(command, stderr=subprocess.STDOUT)
        process.wait()
        xbmc.log("%s: run returned %s" % (__addonname__, process.returncode), xbmc.LOGDEBUG)
    except:
        xbmc.log("%s: Failed to execute %s: %s" % (__addonname__, " ".join(command), traceback.format_exc()), xbmc.LOGDEBUG)

def kill(command) :
    xbmc.log('%s: kill \"%s\"' % (__addonname__, ' '.join(command)), xbmc.LOGDEBUG)
    try:
        os.system("taskkill /im %s" % command)
        xbmc.log("%s: kill returned" % (__addonname__), xbmc.LOGDEBUG)
    except:
        xbmc.log("%s: Failed to kill %s: %s" % (__addonname__, command, traceback.format_exc()), xbmc.LOGDEBUG)

def getExecPath(program) :
    # append .exe for windows
    return os.path.join(__addonpath__, 'exec', program + '.exe')
