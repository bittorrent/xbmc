MEDIA_SERVER_S3_BUCKET = 'bt-play'
MEDIA_SERVER_S3_REGION = 'us-east-1'
MEDIA_SERVER_S3_CREDS_VIA_JENKINS = 'bt-play-rw'
WIN_BUNDLED_SOFTWARE_PATH = 'media_server/bundled_software/windows'
WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER = 'BitTorrent.exe'
WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER = 'Bonjour64.msi'
WIN_BUNDLED_SOFTWARE_FFMPEGE_STATIC = 'ffmpeg.exe'

pipeline {
	agent none
	parameters {
		string(name: 'branch_to_build', defaultValue: 'origin/develop', description: 'The git branch to build.')	
	}
	stages {
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
					stage('Download Bundled Software') {
						withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER, bucket: MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_BITTORRENT_INSTALLER}", force:true)
						}
						withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER, bucket: MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_BONJOUR_INSTALLER}", force:true)
						}
						withAWS(region: MEDIA_SERVER_S3_REGION, credentials: MEDIA_SERVER_S3_CREDS_VIA_JENKINS) {
							s3Download(file: WIN_BUNDLED_SOFTWARE_FFMPEGE_STATIC, bucket: MEDIA_SERVER_S3_BUCKET, path: "${WIN_BUNDLED_SOFTWARE_PATH}/${WIN_BUNDLED_SOFTWARE_FFMPEGE_STATIC}", force:true)
						}
					}
					stage('Build') {
						bat 'jenkins_build_play_mediaserver_win.bat'
							
					}
					stage('Archive Build Artifacts') {
						always {
							archive "project/Win32BuildSetup/BUILD_WIN32/**"
						}
					}
				}
			}
			
		}
	}	
}
