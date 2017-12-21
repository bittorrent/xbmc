MEDIA_SERVER_S3_BUCKET = 'bt-play'
MEDIA_SERVER_S3_REGION = 'us-east-1'
MEDIA_SERVER_S3_CREDS_VIA_JENKINS = 'bt-play-rw'
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
	}
	stages {
		stage('Build on Windows') {
			agent {
				//label 'windows'
        label 'Joes_PC'
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
            //when {
            //  expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
            //}
            steps {
              dir ('project\\Win32BuildSetup') {
                bat 'python %WORKSPACE%\\jenkins-pre-sign.py %JENKINS_CODE_SIGNING_KEY% .\\BUILD_WIN32'
              }
            }
          }

          stage ('Assemble pre-signed exe') {
            //when {
            //    expression { return env.BRANCH_NAME.startsWith('release/') || env.BRANCH_NAME.startsWith('support/') }
            //}
            steps {
              dir ('project\\Win32BuildSetup') {
                bat 'call .\\BuildSetup.bat noclean nomingwlibs installer_only'
              }
            }
          }

          stage ('Upload pre-signed exe') {
            steps {
              dir ('project\\Win32BuildSetup') {
                withAWS(region: 'us-east-1', credentials: 'jenkins-play-main-org') {
                  s3Upload(file: "Play*.exe", bucket: "bt-build-artifacts", path: "play/${BUILD_NUMBER}/Play.exe")
                }
              }
            }
          }

          stage ('Notary') {
            steps {
              bat 'curl -v -X POST "https://notary.bittorrent.com/api/v1/jobs?input_file_path=play/%BUILD_NUMBER%/Play.exe&output_sig_types=authenticode&track=stable&app_name=play&platform=win&job_name=play&build_num=%BUILD_NUMBER%&app_url=https://www.bittorrent.com"'
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
