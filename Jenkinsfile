#!groovy

MEDIA_SERVER_JENKINS_CREDS_PRE_SIGNING_KEY_ID = "JenkinsPreSignKey"
MEDIA_SERVER_JENKINS_CREDS_SENSITIVE_BUILD_STRINGS_ID = "mediaserver_sensitive_build_strings"
MEDIA_SERVER_S3_CREDS_VIA_JENKINS = "bt-play-rw"

BT_JENKINS_ARTIFACT_BUCKET = ''
MEDIA_SERVER_S3_BUCKET = ''
MEDIA_SERVER_S3_REGION = ''
MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL = ''
WIN_BUNDLED_SOFTWARE_PATH = 'media_server/bundled_software/windows'
WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER = 'BitTorrent.exe'
WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER = 'Bonjour64.msi'
WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC = 'ffmpeg.exe'
BT_TRANSCODE_FFMPEG_PATH = 'addons\\script.bt.transcode\\exec'
WIN_BUILD_DEPS_PATH = 'project\\BuildDependencies'
WIN_BUILD_PATH = 'project\\Win32BuildSetup'
WIN_BUILD_OUTPUT_PATH = "${WIN_BUILD_PATH}\\BUILD_WIN32"
WIN_BUILD_SCRIPT = 'BuildSetup.bat'
WIN_DOWNLOAD_BUILD_DEPS_SCRIPT = 'DownloadBuildDeps.bat'
WIN_DOWNLOAD_MINGW_ENV_SCRIPT = 'DownloadMingwBuildEnv.bat'

pipeline {
	agent any
	parameters {
		//string(name: 'branch_to_build', defaultValue: 'origin/develop', description: 'The git branch to build.')
		string(name: 'build_setup_args', defaultValue: "noclean nomingwlibs", description: "Build args, defaults to 'noclean nomingwlings' for fast builds, leave empty for a full build.")
		booleanParam(name: 'perform_signing', defaultValue: false, description: "Build and sign the artifacts and installer? Default is 'False'.")
	}

    environment {
        JENKINS_CODE_SIGNING_KEY = credentials("${MEDIA_SERVER_JENKINS_CREDS_PRE_SIGNING_KEY_ID}")
        MEDIA_SERVER_S3_BUCKET = credentials("MediaServerS3Bucket")
        MEDIA_SERVER_S3_REGION = credentials("MediaServerS3Region")
        MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL = credentials("MediaServerSigningNotaryServerUrl")
    }
	
	stages {
        stage('Determine Build Settings') {
            agent any
            steps {
                script { 
                    if ((env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/')) || params.perform_signing) {
                        echo "Signing this build"
                        env.SIGN_BUILD = true
                    }
                    else {
                        echo "Not signing this build"
                        env.SIGN_BUILD = false
                    }
                }
            }
        }
		stage('Build on Windows') {
			agent {
                    //label 'windows'
                    label 'Windows_Build_Slave'
			}
			
			steps {
				script {
					stage('Checkout Source') {
						checkout scm
					}
					stage('Prep Git Submodules') {
						bat "git submodule update --init --recursive addons\\*bt*"
					}
					stage('Download Bundled Software') {
						withAWS(region: env.MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER, bucket: env.MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER}", force:true)
						}
						withAWS(region: env.MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER, bucket: env.MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER}", force:true)
						}
						withAWS(region: env.MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC, bucket: env.MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC}", force:true)
						}
						bat "Echo moving the ffmpeg static exe to the proper location for build."
						bat "del ${BT_TRANSCODE_FFMPEG_PATH}\\${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC}"
						bat "move ${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC} ${BT_TRANSCODE_FFMPEG_PATH}\\${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC}"
					}
					stage('Download XBMC DEPS') {
						bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_BUILD_DEPS_SCRIPT}"
					}
					stage('Download Mingw Build Env') {
						bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_MINGW_ENV_SCRIPT}"
					}
					stage('Build') {
						bat "cd ${WIN_BUILD_PATH} && ${WIN_BUILD_SCRIPT} ${params.build_setup_args}"
					}
                }
            }
            post {
				success {
					archive "project/Win32BuildSetup/BUILD_WIN32/**"
				}
			}
        }
        stage ('Sign on Windows') {
            agent {
                    //label 'windows'
                    label 'Windows_Build_Slave'
			}
            when {
                expression {
                    return env.SIGN_BUILD
                }
            }
            environment {
                PATH = "${LOCALAPPDATA}\\Programs\\Python\\Python36-32;${PATH}"
            }
            steps {
                echo "Pre-sign..."
                dir ('project\\Win32BuildSetup') {
                    bat 'python %WORKSPACE%\\jenkins-pre-sign.py %JENKINS_CODE_SIGNING_KEY% .\\BUILD_WIN32'
                }

                echo "Assemble pre-signed exe"
                dir ('project\\Win32BuildSetup') {
                    bat 'call .\\BuildSetup.bat noclean nomingwlibs nsis'
                }

                echo "Faked pre-signed exe"
                withAWS(region: env.MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JEKINS) {
                    s3Download(file: "test", bucket: env.MEDIA_SERVER_S3_BUCKET, path: "test_presigning/63/play.exe", force:true)
                }
                dir ('test\\test_presigning\\63') {
                    bat 'dir'
                }

                echo "Upload pre-signed exe"
                dir ('test\\test_presigning\\63') {
                    withAWS(region: env.MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JEKINS) {
                        s3Upload(file: ".\\play.exe", bucket: env.BT_JENKINS_ARTIFACT_BUCKET, path: "play/9999/play.exe")
                    }
                }

                echo "Notary"
                bat "call wget '${env.MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL}'"
            }
        }
	}	
}
