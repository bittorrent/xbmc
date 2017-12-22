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
			label 'Joes_PC'
		}
	}

	parameters {
		//string(name: 'branch_to_build', defaultValue: 'origin/develop', description: 'The git branch to build.')
		string(name: 'build_setup_args', defaultValue: "noclean nomingwlibs", description: "Build args, defaults to 'noclean nomingwlings' for fast builds, leave empty for a full build.")
		booleanParam(name: 'perform_signing', defaultValue: false, description: "Build and sign the artifacts and installer? Default is 'False'.")
	}

	environment {
    PLAY_S3_CREDS = credentials("AWS_PLAY_MOBILE_ORG_ID")
    MAIN_S3_CREDS = credentials("AWS_PLAY_MAIN_ORG_ID")
		JENKINS_CODE_SIGNING_KEY = credentials("JenkinsPreSignKey")
		MEDIA_SERVER_S3_BUCKET = credentials("MediaServerS3Bucket")
		MEDIA_SERVER_S3_REGION = credentials("MediaServerS3Region")
    BUILD_ARTIFACTS_S3_BUCKET = credentials("BuildArtifactsS3Bucket")
		MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL = credentials("MediaServerSigningNotaryServerUrl")
		PATH = "${LOCALAPPDATA}\\Programs\\Python\\Python36-32;${PATH}"
	}

	stages {
		stage('Checkout Source') {
      steps {
        checkout scm
        bat "git submodule update --init --recursive addons\\*bt*"
      }
//      when {
//        expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
//      }
//      steps {
//        bat 'git clean -xdf'
//      }
		}

    /*
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
        echo ""
				bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_BUILD_DEPS_SCRIPT}"
      }
		}

		stage('Download Mingw Build Env') {
      steps {
        bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_MINGW_ENV_SCRIPT}"
      }
		}

		stage('Build') {
      steps {
        bat "cd ${WIN_BUILD_PATH} && ${WIN_BUILD_SCRIPT} ${params.build_setup_args}"
      }
		}
    */

    stage ('Pre-sign') {
//      when {
//        expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
//      }
      steps {
        dir ('project\\Win32BuildSetup') {
          bat "python ${WORKSPACE}\\jenkins-pre-sign.py ${JENKINS_CODE_SIGNING_KEY} .\\BUILD_WIN32"
        }
      }
    }

    stage ('Assemble pre-signed exe') {
//      when {
//        expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
//      }
      steps {
        dir ('project\\Win32BuildSetup') {
          bat 'call .\\BuildSetup.bat installeronly'
        }
      }
    }

    stage ('Upload pre-signed exe') {
//      when {
//        expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
//      }
      steps {
        dir ('project\\Win32BuildSetup') {
          bat 'copy /y PlaySetup*.exe Play.exe'
          withAWS(region: "${MEDIA_SERVER_S3_REGION}", credentials: "${MAIN_S3_CREDS}") {
            s3Upload(file: "Play.exe", bucket: "${BUILD_ARTIFACTS_S3_BUCKET}", path: "play/${BUILD_NUMBER}/Play.exe")
          }
        }
      }
    }

    stage ('Notary Signing') {
//      when {
//          expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
//      }
      steps {
        bat 'curl -v -X POST "${MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL}input_file_path=play/%BUILD_NUMBER%/Play.exe&output_sig_types=authenticode&track=stable&app_name=play&platform=win&job_name=play&build_num=%BUILD_NUMBER%&app_url=https://www.bittorrent.com"'
      }
    }
	}
}
