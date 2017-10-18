import xbmc
import xbmcaddon
import os, sys
import stat
import subprocess
import traceback
import json
import urllib
import time

from transcode import movieTranscodeForStreaming, movieTranscodeForDownload

if os.name == 'nt' :
    from sys_nt import run, kill, getExecPath
elif os.name == 'posix' :
    from sys_posix import run, kill, getExecPath
else :
    raise ValueError('unsupported os \"%s\"' % os.name)

__addon__ = xbmcaddon.Addon()
__addonname__ = __addon__.getAddonInfo('name')
__addonpath__ = __addon__.getAddonInfo('path')
__ffmpeg__ = getExecPath('ffmpeg')

__tempdir__ = xbmc.translatePath('special://temp')
__encodingdir__ = os.path.join(__tempdir__, 'temp_encoded')
__pidfile__ = os.path.join(__tempdir__, 'ffmpeg_pid')

# get all of the movies 'file' parameter (the paths to the movie files)
def getMovies() :
    json_query = xbmc.executeJSONRPC('{ "jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "params": {"properties" : ["file"]}, "id": 1 }')
    json_query = unicode(json_query, 'utf-8', errors='ignore')
    json_query = json.loads(json_query)
    movies = json_query['result']['movies']
    return movies

# match the basename of the requested path w/ the movie database path
# FIXME - eventually, the client should pass in a local file path which it
# should be able to get from getting its info via jsonrpc instead of upnp
# for now, the path comes from upnp and we guess which movie it is
# to get the local path.
def getMoviePathFromUpnpPath(inputFile) :
    movies = getMovies()
    for movie in movies :
        filename = movie['file']
        if  os.path.basename(urllib.unquote(inputFile)) == os.path.basename(filename) :
            return filename

def killFfmpeg() :
    pid = readPidFromFile()
    if pid :
        kill(pid)

def cleanUpFiles(playlistFile) :
    basename, extension = os.path.splitext(playlistFile)
    for f in os.listdir(__encodingdir__):
        if f.startswith(basename):
            try :
                os.remove(os.path.join(__encodingdir__, f))
            except:
                xbmc.log("%s: Failed to remove %s: %s" % (__addonname__, f, traceback.format_exc()), xbmc.LOGDEBUG)

def cleanUpServer(playlistFile) :
    killFfmpeg()
    xbmc.log("%s: cleanup files for %s" % (__addonname__, playlistFile), xbmc.LOGDEBUG)
    for i in xrange(10) :
        cleanUpFiles(playlistFile)
        time.sleep(1)
        if not os.path.isfile(os.path.join(__encodingdir__, playlistFile)) :
            break

# write the PID to a file so we can read it later and issue a kill
def writePidToFile(pid) :
    if not pid :
        return
    try:
        # Write PID file
        pidfile = open(__pidfile__, 'w')
        pidfile.write(str(pid))
        pidfile.close()
    except:
        xbmc.log('%s: Failed to write %s: %s' % (__addonname__, __pidfile__, traceback.format_exc()), xbmc.LOGDEBUG)

def readPidFromFile() :
    try:
        pidfile = open(__pidfile__, 'r')
        pid = pidfile.readline().strip()
        pidfile.close()
        os.remove(__pidfile__)
    except:
        pid = None
        xbmc.log('%s: Failed to read %s: %s' % (__addonname__, __pidfile__, traceback.format_exc()), xbmc.LOGDEBUG)
    return pid

#########################
# Main
#########################
if __name__ == '__main__':
    inputFile = sys.argv[1]     # file to transcode
    mode = sys.argv[2]          # 'stream'|'download'
    destination = sys.argv[3]   # output destination

    if 'download' == mode :
        # for 'download', destination is 'http://<host>:<port>/<filename>'
        pid = run([__ffmpeg__] + movieTranscodeForDownload(getMoviePathFromUpnpPath(inputFile), destination))
        writePidToFile(pid)
    elif 'stream' == mode :
        # for 'stream', destination is an m3u8 filename to which we append the
        # temporary encoding path
        destination = os.path.join(__encodingdir__, destination)
        pid = run([__ffmpeg__] + movieTranscodeForStreaming(getMoviePathFromUpnpPath(inputFile), destination))
        writePidToFile(pid)
    elif 'stream_cleanup' == mode :
        cleanUpServer(destination)
    elif 'download_cleanup' == mode :
        killFfmpeg()
    else :
        xbmc.log('%s: Unknown mode "%s"' % (__addonname__, mode), xbmc.LOGERROR)
