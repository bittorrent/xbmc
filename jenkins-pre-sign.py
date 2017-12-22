import os
import base64
import subprocess
import sys
import argparse

SIGNTOOL_PATH = "C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x86"

def sign_file(key_path, file_path):
    cmd = "\"{st_path}\" sign /f {key_path} /t {ts_srv} /d {d_param} /du {du_param} {file_path} ".format(st_path=os.path.join(SIGNTOOL_PATH, "signtool.exe"),
                    key_path=key_path,
                    ts_srv="http://timestamp.verisign.com/scripts/timstamp.dll",
                    d_param="AdsSDK",
                    du_param="http://www.gyre.com",
                    file_path=file_path)

    print("{} running: {} ".format(__file__, cmd))

    subprocess.run(cmd, shell=True)

def main():
    parser = argparse.ArgumentParser(description="Sign a file with a given key")
    parser.add_argument("key_path", type=str, help="Key file")
    parser.add_argument("file_path", type=str, help="File to sign")
    args = parser.parse_args()

    KEY_PATH = args.key_path
    FILE_PATH = args.file_path

    print("KEY_PATH={}".format(KEY_PATH))
    print("FILE_PATH={}".format(FILE_PATH))

    if (not os.path.exists(KEY_PATH)):
        print("Cannot find KEY_PATH.\nAborting!!!!")
        exit(-1)

    if (not os.path.exists(FILE_PATH)):
        print("Cannot find FILE_PATH.\nAborting!!!!")
        exit(-1)

    # handle the Play.exe file alone
    if os.path.isfile(FILE_PATH):
        sign_file(KEY_PATH, os.path.abspath(FILE_PATH))
    else:
        # handle a dir of files
        for root, subFolders, files in os.walk(FILE_PATH):
            for file in files:
                f = os.path.join(root,file)
                if (f.endswith('.dll') or f.endswith('.exe')):
                    sign_file(KEY_PATH, f)
                else:
                    print("skipping %s" % f)

if __name__ == "__main__":
    main()
