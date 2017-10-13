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

__serviceaddon__ = xbmcaddon.Addon('service.bt.transcode')
__serviceaddonpath__ = __serviceaddon__.getAddonInfo('path')
__encodingdir__ = os.path.join(__serviceaddonpath__, '.temp_encoded')

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

def cleanUpFiles(playlistFile) :
    basename, extension = os.path.splitext(playlistFile)
    for f in os.listdir(__encodingdir__):
        if f.startswith(basename):
            try :
                os.remove(os.path.join(__encodingdir__, f))
            except:
                xbmc.log("%s: Failed to remove %s: %s" % (__addonname__, f, traceback.format_exc()), xbmc.LOGDEBUG)

def cleanUpServer(playlistFile) :
    kill("ffmpeg")
    xbmc.log("%s: cleanup files for %s" % (__addonname__, playlistFile), xbmc.LOGDEBUG)
    for i in xrange(10) :
        cleanUpFiles(playlistFile)
        time.sleep(1)
        if not os.path.isfile(os.path.join(__encodingdir__, playlistFile)) :
            break

#########################
# Main
#########################
if __name__ == '__main__':
    inputFile = sys.argv[1]     # file to transcode
    mode = sys.argv[2]          # 'stream'|'download'
    destination = sys.argv[3]   # output destination

    if 'download' == mode :
        # for 'download', destination is 'http://<host>:<port>/<filename>'
        run([__ffmpeg__] + movieTranscodeForDownload(getMoviePathFromUpnpPath(inputFile), destination))
    elif 'stream' == mode :
        # for 'stream', destination is an m3u8 filename to which we append the
        # temporary encoding path
        destination = os.path.join(__encodingdir__, destination)
        run([__ffmpeg__] + movieTranscodeForStreaming(getMoviePathFromUpnpPath(inputFile), destination))
    elif 'stream_cleanup' == mode :
        cleanUpServer(destination)
    else :
        xbmc.log('%s: Unknown mode "%s"' % (__addonname__, mode), xbmc.LOGERROR)
