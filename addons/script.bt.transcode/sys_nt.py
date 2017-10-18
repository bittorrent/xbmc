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
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        process = subprocess.Popen(command, startupinfo=startupinfo)
        process.wait()
        xbmc.log("%s: run returned %s" % (__addonname__, process.returncode), xbmc.LOGDEBUG)
    except:
        xbmc.log("%s: Failed to execute %s: %s" % (__addonname__, " ".join(command), traceback.format_exc()), xbmc.LOGDEBUG)
    return process.pid

def kill(pid) :
    xbmc.log('%s: kill ffmpeg pid %s' % (__addonname__, pid), xbmc.LOGDEBUG)
    try:
        os.system('taskkill /f /t /pid %s' % pid)
    except:
        xbmc.log('%s: Failed to kill pid %s: %s' % (__addonname__, pid, traceback.format_exc()), xbmc.LOGDEBUG)

def getExecPath(program) :
    # append .exe for windows
    return os.path.join(__addonpath__, 'exec', program + '.exe')
