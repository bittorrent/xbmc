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
	agent none
	parameters {
		//string(name: 'branch_to_build', defaultValue: 'origin/develop', description: 'The git branch to build.')
		string(name: 'build_setup_args', defaultValue: "noclean nomingwlibs", description: "Build args, defaults to 'noclean nomingwlings' for fast builds, leave empty for a full build.")
		booleanParam(name: 'perform_signing', defaultValue: false, description: "Build and sign the artifacts and installer? Default is 'False'.")
	}


    environment {
        JENKINS_CODE_SIGNING_KEY = credentials("${MEDIA_SERVER_JENKINS_CREDS_PRE_SIGNING_KEY_ID}")
    }

	stages {
		stage('Determine Build Settings') {
			agent any

			steps {
                script {
                    if ((env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/')) || ${params.perform_signing}) {
                        echo "Due to branch name ${env.BRANCH_NAME} or param override: perform_signing = ${params.perform_signing} this build will be signed."
                        env.SIGN_BUILD = true
                    }
                    else {
                        echo "Due to branch name ${env.BRANCH_NAME} or param override: perform_signing = ${params.perform_signing} this build will NOT be signed."
                        env.SIGN_BUILD = false
                    }
                }
			}
		}
		stage('Build on Windows') {
			agent {
                node {
                    label 'Joes_PC'

                        withCredentials([[$class: 'FileBinding', credentialsId: "${MEDIA_SERVER_JENKINS_CREDS_SENSITIVE_BUILD_STRINGS_ID}", variable: 'SENSITIVE_BUILD_STRINGS_FILE']]) {
                    //withCredentials( [file(credentialsId: "${MEDIA_SERVER_JENKINS_CREDS_SENSITIVE_BUILD_STRINGS_ID}", variable: 'SENSITIVE_BUILD_STRINGS_FILE')]) {
                        sensitive_strings = readProperties(SENSITIVE_BUILD_STRINGS_FILE)

                        env.MEDIA_SERVER_S3_BUCKET = sensitive_strings['MEDIA_SERVER_S3_BUCKET']
                        env.MEDIA_SERVER_S3_REGION = sensitive_strings['MEDIA_SERVER_S3_REGION']
                        env.MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL = sensitive_strings['MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL']
                    }
                }
			}
			environment {
            	PATH = "${LOCALAPPDATA}\\Programs\\Python\\Python36-32;${PATH}"
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
						withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER, bucket: MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER}", force:true)
						}
						withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER, bucket: MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER}", force:true)
						}
						withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC, bucket: MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC}", force:true)
						}
						bat "Echo moving the ffmpeg static exe to the proper location for build."
						bat "del ${BT_TRANSCODE_FFMPEG_PATH}\\${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC}"
						bat "move ${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC} ${BT_TRANSCODE_FFMPEG_PATH}\\${WIN_BUNDLED_SOFTWARE_FFMPEG_STATIC}"
					}
					stage('Download XBMC DEPS') {
						echo ""
						bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_BUILD_DEPS_SCRIPT}"
					}
					stage('Download Mingw Build Env') {
						bat "cd ${WIN_BUILD_DEPS_PATH} && ${WIN_DOWNLOAD_MINGW_ENV_SCRIPT}"
					}
					stage('Build') {
						bat "cd ${WIN_BUILD_PATH} && ${WIN_BUILD_SCRIPT} ${params.build_setup_args}"
					}
					stage ('Pre-sign') {
						if (env.SIGN_BUILD) {
							dir ('project\\Win32BuildSetup') {
						  		bat 'python %WORKSPACE%\\jenkins-pre-sign.py %JENKINS_CODE_SIGNING_KEY% .\\BUILD_WIN32'
							}
						}
					}
					stage ('Assemble pre-signed exe') {
						if (env.SIGN_BUILD) {
							dir ('project\\Win32BuildSetup') {
						  		bat 'call .\\BuildSetup.bat noclean nomingwlibs nsis'
							}
						}
					}
					stage ('Faked pre-signed exe') {
						if (env.SIGN_BUILD) {
							withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JEKINS) {
								s3Download(file: "test", bucket: MEDIA_SERVER_S3_BUCKET, path: "test_presigning/63/play.exe", force:true)
							}
							dir ('test\\test_presigning\\63') {
								bat 'dir'
							}
						}
					}
					stage ('Upload pre-signed exe') {
						if (env.SIGN_BUILD) {
							dir ('test\\test_presigning\\63') {
								withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JEKINS) {
									s3Upload(file: ".\\play.exe", bucket: BT_JENKINS_ARTIFACT_BUCKET, path: "play/9999/play.exe")
								}
							}
						}
					}
					stage ('Notary') {
						if (env.SIGN_BUILD) {
							bat "call wget '${env.MEDIA_SERVER_SIGNING_NOTARY_SERVER_URL}'"
						}
					}
				}
			}
			post {
				always {
					archive "project/Win32BuildSetup/BUILD_WIN32/**"
				}
			}
		}
	}
}
