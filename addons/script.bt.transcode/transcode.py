import traceback
import json

def getVideoArgs() :
    retArgs = []
    retArgs += ['-c:v', 'libx264']
    retArgs += ['-preset', 'veryfast']
    retArgs += ['-crf', '26']
    retArgs += ['-pix_fmt', 'yuv420p']
    return retArgs

def getAudioArgs() :
    retArgs = []
    retArgs += ['-c:a', 'aac']
    retArgs += ['-strict', 'experimental']
    retArgs += ['-ac', '2']
    retArgs += ['-ar', '48000']
    retArgs += ['-ab', '160000']
    return retArgs

def getOptimizationArgs() :
    retArgs = []
    retArgs += ['-movflags', 'frag_keyframe+empty_moov']  # for streaming from a partial (fragmented) file
    return retArgs

def movieTranscodeForStreaming(infile, destination) :
    cmdArgs = []

    # input file path
    cmdArgs += ['-i', infile]

    # video stream arguments
    cmdArgs += getVideoArgs()

    # audio stream arguments
    cmdArgs += getAudioArgs()

    # optimization flags
    # cmdArgs += getOptimizationArgs()

    cmdArgs += ['-profile:v', 'baseline', '-level', '3.0', '-s', '640x360']

    cmdArgs += ['-start_number', '0', '-hls_time', '10', '-hls_list_size', '0']

    cmdArgs += ['-f', 'hls']

    cmdArgs += [destination]

    return cmdArgs

def movieTranscodeForDownload(infile, destination) :
    cmdArgs = []

    # input file path
    cmdArgs += ['-i', infile]

    # video stream arguments
    cmdArgs += getVideoArgs()

    # audio stream arguments
    cmdArgs += getAudioArgs()

    # optimization flags
    cmdArgs += getOptimizationArgs()

    # use ffmpeg experimental server to wait for connection to serve file
    cmdArgs += ['-listen', '1']

    # set the output format to mp4
    cmdArgs += ['-f', 'mp4']

    cmdArgs += [destination]

    return cmdArgs
