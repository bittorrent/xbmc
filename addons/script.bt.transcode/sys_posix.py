##########################################
# Posix (OSX) specific System functions
##########################################
import xbmc
import xbmcaddon
import os, sys
import subprocess
import traceback

__addon__ = xbmcaddon.Addon()
__addonname__ = __addon__.getAddonInfo('name')
__addonpath__ = __addon__.getAddonInfo('path')

__serviceaddon__ = xbmcaddon.Addon('service.bt.transcode')
__serviceaddonpath__ = __serviceaddon__.getAddonInfo('path')
__pidfile__ = os.path.join(__serviceaddonpath__, '.ffmpeg_pid')

def run(command) :
    xbmc.log('%s: run \"%s\"' % (__addonname__, ' '.join(command)), xbmc.LOGDEBUG)
    try:
        process = subprocess.Popen(command, stderr=subprocess.STDOUT)
        xbmc.log('%s: run returned %s' % (__addonname__, process.returncode), xbmc.LOGDEBUG)
    except:
        xbmc.log('%s: Failed to execute %s: %s' % (__addonname__, ' '.join(command), traceback.format_exc()), xbmc.LOGDEBUG)
    return process.pid

def kill(pid) :
    xbmc.log('%s: kill ffmpeg pid %s' % (__addonname__, pid), xbmc.LOGDEBUG)
    try:
        os.kill(int(pid), signal.SIGKILL)
    except:
        xbmc.log('%s: Failed to kill %s: %s' % (__addonname__, pid, traceback.format_exc()), xbmc.LOGDEBUG)

def getExecPath(program) :
    return os.path.join(__addonpath__, 'exec', program)
