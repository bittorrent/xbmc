import time
import xbmc
import xbmcaddon
import os
import SimpleHTTPServer
import SocketServer
import threading

__addon__ = xbmcaddon.Addon()
__addonname__ = __addon__.getAddonInfo('name')

__tempdir__ = xbmc.translatePath('special://temp')
__encodingdir__ = os.path.join(__tempdir__, 'temp_encoded')

HTTPD_PORT = 9000

class HttpServer() :
    def __init__(self) :
        if not os.path.exists(__encodingdir__):
            os.makedirs(__encodingdir__)

        os.chdir(__encodingdir__)

        Handler = SimpleHTTPServer.SimpleHTTPRequestHandler
        Handler.extensions_map.update({
            '.webapp': 'application/x-web-app-manifest+json',
        });

        self.httpd = SocketServer.TCPServer(("", HTTPD_PORT), Handler)
        self.thread = threading.Thread(target = self.httpd.serve_forever)
        self.thread.setdaemon = True
        self.thread.start()

    def stop(self) :
        xbmc.log("%s: httpd server shutting down! %s" % (__addonname__, time.time()), level=xbmc.LOGDEBUG)
        self.httpd.shutdown()
        xbmc.log("%s: removing dangling transcoded files %s" % (__addonname__, time.time()), level=xbmc.LOGDEBUG)
        # remove all files in the temporary encoding directory
        for f in os.listdir(__encodingdir__):
            try :
                os.remove(os.path.join(__encodingdir__, f))
            except:
                xbmc.log("%s: Failed to remove %s: %s" % (__addonname__, f, traceback.format_exc()), xbmc.LOGDEBUG)

if __name__ == '__main__':
    monitor = xbmc.Monitor()

    httpd = HttpServer()

    while not monitor.abortRequested():
        # Sleep/wait for abort for 10 seconds
        if monitor.waitForAbort(10):
            # Abort was requested while waiting. We should exit
            break
        xbmc.log("%s: httpd server running! %s" % (__addonname__, time.time()), level=xbmc.LOGDEBUG)

    httpd.stop()
