#!groovy

BT_JENKINS_ARTIFACT_BUCKET = ''
WIN_BUNDLED_SOFTWARE_PATH = 'media_server/bundled_software/windows/'
BITTORRENT_INSTALLER = 'BitTorrent.exe'
WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER = WIN_BUNDLED_SOFTWARE_PATH + BITTORRENT_INSTALLER
BONJOUR_INSTALLER = 'Bonjour64.msi'
WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER = WIN_BUNDLED_SOFTWARE_PATH + BONJOUR_INSTALLER
FFMPEG_STATIC = 'ffmpeg.exe'
WIN_BUNDLED_SOFTWARE_FFMPEG_PATH = WIN_BUNDLED_SOFTWARE_PATH + FFMPEG_STATIC
BT_TRANSCODE_FFMPEG_PATH = 'addons\\script.bt.transcode\\exec\\' + FFMPEG_STATIC
WIN_BUILD_DEPS_PATH = 'project\\BuildDependencies'
WIN_BUILD_PATH = 'project\\Win32BuildSetup'
WIN_BUILD_OUTPUT_PATH = "${WIN_BUILD_PATH}\\BUILD_WIN32"
WIN_BUILD_SCRIPT = 'BuildSetup.bat'
WIN_DOWNLOAD_BUILD_DEPS_SCRIPT = 'DownloadBuildDeps.bat'
WIN_DOWNLOAD_MINGW_ENV_SCRIPT = 'DownloadMingwBuildEnv.bat'

pipeline {
  agent {
    node {
      label 'windows'
    }
  }

  parameters {
    string(name: 'build_setup_args', defaultValue: "noclean nomingwlibs", description: "Build args, defaults to 'noclean nomingwlings' for fast builds, leave empty for a full build.")
    booleanParam(name: 'skip_deps_and_mingw', defaultValue: false, description: "Skips downloading the xbmc deps and building of the mingq build env, only use this if you know what you are doing.")
    booleanParam(name: 'override_release_build_check', defaultValue: false, description: "Overrides the release branch check when building so that 'build_setup_args' is respected.")
  }

  environment {
    PLAY_S3_CREDS = credentials("AWS_PLAY_MOBILE_ORG_ID")
    MAIN_S3_CREDS = credentials("AWS_PLAY_MAIN_ORG_ID")
    JENKINS_CODE_SIGNING_KEY = credentials("JenkinsPreSignKey")
    MEDIA_SERVER_S3_BUCKET = credentials("MediaServerS3Bucket")
    MEDIA_SERVER_S3_REGION = credentials("MediaServerS3Region")
    BUILD_ARTIFACTS_S3_BUCKET = credentials("BuildArtifactsS3Bucket")
    SIGNED_ARTIFACTS_S3_BUCKET = credentials("SignedArtifactsS3Bucket")
    MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL = credentials("MediaServerSigningNotaryServerUrl")
    PATH = "${LOCALAPPDATA}\\Programs\\Python\\Python36-32;${PATH}"
  }

  stages {
    stage('Checkout Source') {
      steps {
        checkout scm
        bat "git submodule update --init --recursive addons\\*bt*"
        script {
          release = env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/')
          if (release) {
            bat "git config core.longpaths true"
            bat "git clean -xdf"
          }
        }
      }
    }

    stage('Download Bundled Software') {
      steps {
        withAWS(region: "${MEDIA_SERVER_S3_REGION}", credentials: "${PLAY_S3_CREDS}") {
          s3Download(file: BITTORRENT_INSTALLER, bucket: "${MEDIA_SERVER_S3_BUCKET}", path: WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER, force:true)
          s3Download(file: BONJOUR_INSTALLER, bucket: "${MEDIA_SERVER_S3_BUCKET}", path: WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER, force:true)
          s3Download(file: FFMPEG_STATIC, bucket: "${MEDIA_SERVER_S3_BUCKET}", path: WIN_BUNDLED_SOFTWARE_FFMPEG_PATH, force:true)
        }
        bat "Echo moving the ffmpeg static exe to the proper location for build."
        bat "del ${BT_TRANSCODE_FFMPEG_PATH}"
        bat "move ${FFMPEG_STATIC} ${BT_TRANSCODE_FFMPEG_PATH}"
      }
    }

    stage('Download XBMC DEPS') {
      steps {
        script {
            if (params.skip_deps_and_mingw == false) {
                bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_BUILD_DEPS_SCRIPT}"
            }
        }
      }
    }

    stage('Download Mingw Build Env') {
      steps {
        script {
            if (params.skip_deps_and_mingw == false) {
                bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_MINGW_ENV_SCRIPT}"
            }
        }
      }
    }

    stage('Build') {
      steps {
        script {
          release = env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/')
          if (release && params.override_release_build_check == false) {
            bat "cd ${WIN_BUILD_PATH} && ${WIN_BUILD_SCRIPT}"
          }
          else {
            bat "cd ${WIN_BUILD_PATH} && ${WIN_BUILD_SCRIPT} ${params.build_setup_args}"
          }
        }
      }
      post {
        success {
          archive "project/Win32BuildSetup/PlaySetup*.exe"
        }
      }
    }

    stage ('Signing') {
      when {
        expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
      }
      steps {
        dir ('project\\Win32BuildSetup') {
          println "presign individual components with self-signed cert"
          powershell "\$currentdir = Get-Location ; \
                      if (Test-Path \$currentdir\\presigned) { \
                        Remove-Item \$currentdir\\presigned -recurse ; \
                      }; \
                      \$presigneddir = New-Item -ItemType directory -force -path \$currentdir\\presigned ; \
                      \$files = Get-ChildItem -File BUILD_WIN32\\application\\ | Where-Object {\$_.extension -eq '.dll' -or \$_.extension -eq '.exe'} ; \
                      foreach (\$file in \$files) { \
                        python ${WORKSPACE}\\jenkins-pre-sign.py ${JENKINS_CODE_SIGNING_KEY} \$file.fullName ; \
                        Copy-Item -force \$file.fullName \$presigneddir.fullName \
                      }"

          println "upload presigned components"
          withAWS(region: "${MEDIA_SERVER_S3_REGION}", credentials: "${MAIN_S3_CREDS}") {
            s3Upload(file: "presigned", bucket: "${BUILD_ARTIFACTS_S3_BUCKET}", path: "play/${BUILD_NUMBER}/presigned/")
          }

          println "notary sign the build artifacts"
          powershell "\$files = Get-ChildItem -File presigned\\ ; \
                      foreach (\$file in \$files) { \
                        &\"C:\\Program Files (x86)\\GnuWin32\\bin\\curl\" -v -X POST \"${MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL}input_file_path=play/${BUILD_NUMBER}/presigned/\$file&output_sig_types=authenticode&track=stable&app_name=play&platform=win&job_name=play&build_num=${BUILD_NUMBER}&app_url=https://www.bittorrent.com\" ; \
                      }"

          powershell "\$currentdir = Get-Location ; \
                      if (Test-Path \$currentdir\\signed) { \
                        Remove-Item \$currentdir\\signed -recurse -force ; \
                      }; \
                      New-Item -ItemType directory -force -path \$currentdir\\signed ; "

          println "downloading notary signed artifacts"
          withAWS(region: "${MEDIA_SERVER_S3_REGION}", credentials: "${MAIN_S3_CREDS}") {
            s3Download(file: "signed/", bucket: "${SIGNED_ARTIFACTS_S3_BUCKET}", path: "play/win/play/${BUILD_NUMBER}/", force:true)
          }

          println "copy the sign artifacts back where they need to be for building the installer"
          powershell "\$currentdir = Get-Location ; \
                      \$files = Get-ChildItem -File \$currentdir\\signed\\play\\win\\play\\${BUILD_NUMBER} ; \
                      foreach (\$file in \$files) { \
                        Copy-Item -force \$file.fullName \$currentdir\\BUILD_WIN32\\application\\ \
                      }"

          println "rebuild the installer"
          bat 'del .\\Play*.exe'
          bat 'call .\\BuildSetup.bat installeronly'

          println "presign the new installer"
          powershell "\$installer = Resolve-Path .\\Play*.exe ; \
                      python ${WORKSPACE}\\jenkins-pre-sign.py ${JENKINS_CODE_SIGNING_KEY} \$installer ; \
                      Copy-Item \$installer -Destination BitTorrentPlay.exe"

          println "upload the presigned installer"
          withAWS(region: "${MEDIA_SERVER_S3_REGION}", credentials: "${MAIN_S3_CREDS}") {
            s3Upload(file: ".\\BitTorrentPlay.exe", bucket: "${BUILD_ARTIFACTS_S3_BUCKET}", path: "play/${BUILD_NUMBER}/Play.exe")
          }

          println "sign the installer"
          powershell "&\"C:\\Program Files (x86)\\GnuWin32\\bin\\curl\" -v -X POST \"${MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL}input_file_path=play/${BUILD_NUMBER}/Play.exe&output_sig_types=authenticode&track=stable&app_name=Play&platform=win&job_name=play&build_num=${BUILD_NUMBER}&app_url=https://www.bittorrent.com\" ;"
        }
      }
    }
  }
}
