pipeline {
 
    agent {
		docker { 
			image 'cpruvost/infraascode:latest'
			args '-u root:root'
		}
	}
	
	//Parameters of the pipeline. You can define more parameters in this pipeline in order to have less hard code variables.
	parameters {
        password(defaultValue: "xxxxxx", description: 'What is the vault token ?', name: 'VAULT_TOKEN')
		string(defaultValue: "130.61.125.123", description: 'What is the vault server IP Address ?', name: 'VAULT_SERVER_IP')
		string(defaultValue: "demoatp", description: 'What is the vault secret name ?', name: 'VAULT_SECRET_NAME')  
		string(defaultValue: "atpdb2", description: 'What is the database name ?', name: 'DATABASE_NAME') 
		password(defaultValue: "AlphA_2014_!", description: 'What is the database password ?', name: 'DATABASE_PASSWORD')  		
		string(defaultValue: "https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/r2849V7j7r4WNhWkT24TOk8BRX7GUe4WfQUfPCPxh3E/n/oraseemeafrtech1/b/AtpDemo2/o/terraform.tfstate", description: 'Where is stored the terraform state ?', name: 'TERRAFORM_STATE_URL')  
		choice(name: 'CHOICE', choices: ['Create', 'Remove'], description: 'Choose between Create or Remove Infrastructure')
    }
	
	//Load the parameters as environment variables
	environment {
		//Vault Env mandatory variables
		VAULT_TOKEN = "${params.VAULT_TOKEN}"
		VAULT_SERVER_IP = "${params.VAULT_SERVER_IP}"
		VAULT_ADDR = "http://${params.VAULT_SERVER_IP}:8200"
		VAULT_SECRET_NAME = "${params.VAULT_SECRET_NAME}"
		CHOICE = "${params.CHOICE}"
		
		//Database variables
		TF_VAR_autonomous_database_db_name = "${params.DATABASE_NAME}"
		TF_VAR_autonomous_database_db_password = "${params.DATABASE_PASSWORD}"
		
		//Terraform variables
		TF_CLI_ARGS = "-no-color"
		TF_VAR_terraform_state_url = "${params.TERRAFORM_STATE_URL}"
		
		//Sqlcl env variables for sqlcl oci option.
		TNS_ADMIN = "./"

	}
    
    stages {
		stage('Display User Name') {
			agent any
            steps {
			    wrap([$class:'BuildUser']) {
				    echo "${BUILD_USER}"
				}
            }
        }
	
        stage('Check Infra As Code Tools') {
            steps {
				sh 'whoami'
				sh 'pwd'
				sh 'ls'
			    sh 'chmod +x ./showtoolsversion.sh'
                sh './showtoolsversion.sh'
            }
        }
		
		stage('Init Cloud Env Variables') {
            steps {
				script {
					//Get all cloud information.
					env.TF_VAR_tenancy_ocid = sh returnStdout: true, script: 'vault kv get -field=tenancy_ocid secret/demoatp'
					env.TF_VAR_user_ocid = sh returnStdout: true, script: 'vault kv get -field=user_ocid secret/demoatp'
					env.TF_VAR_fingerprint = sh returnStdout: true, script: 'vault kv get -field=fingerprint secret/demoatp'
					env.TF_VAR_compartment_ocid = sh returnStdout: true, script: 'vault kv get -field=compartment_ocid secret/demoatp'
					env.TF_VAR_region = sh returnStdout: true, script: 'vault kv get -field=region secret/demoatp'
					env.DOCKERHUB_USERNAME = sh returnStdout: true, script: 'vault kv get -field=dockerhub_username secret/demoatp'
					env.DOCKERHUB_PASSWORD = sh returnStdout: true, script: 'vault kv get -field=dockerhub_password secret/demoatp'
					env.KUBECONFIG = './kubeconfig'
					
					//Terraform debugg option if problem
					//env.TF_LOG="DEBUG"
					//env.OCI_GO_SDK_DEBUG="v"
				}
				
				//Check all cloud information.
				echo "TF_VAR_tenancy_ocid=${TF_VAR_tenancy_ocid}"
				echo "TF_VAR_user_ocid=${TF_VAR_user_ocid}"
				echo "TF_VAR_fingerprint=${TF_VAR_fingerprint}"
				echo "TF_VAR_compartment_ocid=${TF_VAR_compartment_ocid}"
				echo "TF_VAR_region=${TF_VAR_region}"
				echo "TF_VAR_terraform_state_url=${TF_VAR_terraform_state_url}"
				echo "DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME}"
				echo "DOCKERHUB_PASSWORD=${DOCKERHUB_PASSWORD}"
				echo "KUBECONFIG=${KUBECONFIG}"
				
				dir ('./tf/modules/atp') {
					script {
						//Get the API and SSH encoded key Files with vault client because curl breaks the end line of the key file
						sh 'vault kv get -field=api_private_key secret/demoatp | tr -d "\n" | base64 --decode > bmcs_api_key.pem'
						sh 'vault kv get -field=ssh_private_key secret/demoatp | tr -d "\n" | base64 --decode > id_rsa'
						sh 'vault kv get -field=ssh_public_key secret/demoatp | tr -d "\n" | base64 --decode > id_rsa.pub'
						
						//OCI CLI permissions mandatory on some files.
						sh 'oci setup repair-file-permissions --file ./bmcs_api_key.pem'
						
						sh 'ls'
						sh 'cat ./bmcs_api_key.pem'
						sh 'cat ./id_rsa'
						sh 'cat ./id_rsa.pub'
						
						env.TF_VAR_private_key_path = './bmcs_api_key.pem'
						echo "TF_VAR_private_key_path=${TF_VAR_private_key_path}"
						env.TF_VAR_ssh_private_key = sh returnStdout: true, script: 'cat ./id_rsa'
						echo "TF_VAR_ssh_private_key=${TF_VAR_ssh_private_key}"
						env.TF_VAR_ssh_public_key = sh returnStdout: true, script: 'cat ./id_rsa.pub'
						echo "TF_VAR_ssh_public_key=${TF_VAR_ssh_public_key}"
					}
				}
				
				//OCI CLI Setup
				sh 'mkdir -p /root/.oci'
				sh 'rm -rf /root/.oci/config'
				sh 'echo "[DEFAULT]" > /root/.oci/config'
				sh 'echo "user=${TF_VAR_user_ocid}" >> /root/.oci/config'
				sh 'echo "fingerprint=${TF_VAR_fingerprint}" >> /root/.oci/config'
				sh 'echo "key_file=./bmcs_api_key.pem" >> /root/.oci/config'
				sh 'echo "tenancy=${TF_VAR_tenancy_ocid}" >> /root/.oci/config'
				sh 'echo "region=${TF_VAR_region}" >> /root/.oci/config'
				sh 'cat /root/.oci/config'
				
				//OCI CLI permissions mandatory on some files.
				sh 'oci setup repair-file-permissions --file /root/.oci/config'
            }
        }
		
		stage('TF Plan Atp ') { 
            steps {
				dir ('./tf/modules/atp') {
					sh 'ls'
					
					//Terraform initialization in order to get oci plugin provider	
					sh 'terraform init -input=false -backend-config="address=${TF_VAR_terraform_state_url}"'
					
					
					script {
						echo "CHOICE=${env.CHOICE}"
					    //Terraform plan
					    if (env.CHOICE == "Create") {
							//Check if Db is already there
							sh 'oci db autonomous-database list --compartment-id=${TF_VAR_compartment_ocid} --display-name=Demo2_InfraAsCode_ATP --lifecycle-state=AVAILABLE | jq ". | length" > result.test'	
							env.CHECK_DB = sh (script: 'cat ./result.test', returnStdout: true).trim()
							sh 'echo ${CHECK_DB}'
							
							if (env.CHECK_DB == "1") {
								echo "Db Already Exists"
							}
							else {
								sh 'terraform plan -out myplan'
							}
							
						}
						else {
						    sh 'terraform plan -destroy -out myplan'
						}
					}
				}
			}
		}
		
		stage('TF Apply Atp ') { 
            steps {
				dir ('./tf/modules/atp') {
					sh 'ls'
					
					script {				
						echo "CHOICE=${env.CHOICE}"
						
					    //Terraform plan
					    if (env.CHOICE == "Create") {
							
							if (env.CHECK_DB == "1") {
								echo "Db Already Exists"
							}
							else {
								//Ask Question in order to apply terraform plan or not
								def deploy_validation = input(
								id: 'Deploy',
								message: 'Let\'s continue the deploy plan',
								type: "boolean")
							
								sh 'terraform apply -input=false -auto-approve myplan'
							}	
							
							sh 'ls'
							
							//Get atp wallet because initial atp wallet from terraform seems to have problem during unzip.
							sh 'oci db autonomous-database list --compartment-id=${TF_VAR_compartment_ocid} --display-name=Demo2_InfraAsCode_ATP | jq -r .data[0].id > result.test'	
							env.DB_OCID = sh (script: 'cat ./result.test', returnStdout: true).trim()
							sh 'oci db autonomous-database generate-wallet --autonomous-database-id=${DB_OCID} --password=${TF_VAR_autonomous_database_db_password} --file=./myatpwallet.zip'
						}
						else {
						    sh 'terraform destroy -input=false -auto-approve'
						}
					}
				}
			}
		}
		
		stage('Create Schema in Atp') {
            steps {
                dir ('./sql') {
					script {
						if (env.CHOICE == "Create") {
							sh 'pwd'
							sh 'cp ../tf/modules/atp/myatpwallet.zip ./'
							sh 'unzip -o ./myatpwallet.zip'
							sh 'ls'
							//Prepare sqlcl oci option
							sh 'echo $TNS_ADMIN'
							sh 'rm -rf ./sqlnet.ora'
							sh 'mv ./sqlnet.ora.ref ./sqlnet.ora'
							sh 'cat ./tnsnames.ora'
							sh 'cat ./sqlnet.ora'
							//Check Connection to Atp
							sh 'exit | sql -oci admin/${TF_VAR_autonomous_database_db_password}@${TF_VAR_autonomous_database_db_name}_HIGH @./show_version.sql'
							//Create schema in Atp
							sh 'exit | sql -oci admin/${TF_VAR_autonomous_database_db_password}@${TF_VAR_autonomous_database_db_name}_HIGH @./check_schema.sql'
							sh 'ls'
							sh 'cat ./result.test'
						
							env.CHECK_SCHEMA=sh(script: 'cat ./result.test', returnStdout: true).trim()
							
							if (env.CHECK_SCHEMA == "1") {
								sh 'echo "Shema already exist"'
							}
							else {
								sh 'echo "Go Create Shema"'
								sh 'exit | sql -oci admin/${TF_VAR_autonomous_database_db_password}@${TF_VAR_autonomous_database_db_name}_HIGH @./create_schema.sql'
								sh 'exit | sql -oci admin/${TF_VAR_autonomous_database_db_password}@${TF_VAR_autonomous_database_db_name}_HIGH @./create_tables.sql'
							}
						}
						else {
							echo "Nothing To Do Cause Db is Destroyed"
						}
					}	
                }
            }
        }
		
		stage('TF Plan Oke') { 
            steps {
				dir ('./tf/modules/oke') {
					sh 'ls'
					
					//Terraform initialization in order to get oci plugin provider	
					sh 'terraform init -input=false -backend-config="address=${TF_VAR_terraform_state_url}"'
					
					//Get The API Key from Atp
					sh 'cp ../atp/bmcs_api_key.pem ./bmcs_api_key.pem'
					sh 'ls'
					
					script {
						echo "CHOICE=${env.CHOICE}"
						
						//Check if Oke is already there
						sh 'oci ce cluster list --compartment-id=${TF_VAR_compartment_ocid} --name=Demo2_InfraAsCode_OKE --lifecycle-state=ACTIVE | jq ". | length" > result.test'	
						env.CHECK_OKE = sh (script: 'cat ./result.test', returnStdout: true).trim()
						sh 'echo ${CHECK_OKE}'
						
					    //Terraform plan
					    if (env.CHOICE == "Create") {
							if (env.CHECK_OKE == "1") {
								echo "Oke Already Exists"
							}
							else {
								sh 'terraform plan -out myplan'
							}	
						}
						else {
						    sh 'terraform plan -destroy -out myplan'
						}
					}
				}
			}
		}
		
		stage('TF Apply Oke') { 
            steps {
				dir ('./tf/modules/oke') {
					sh 'ls'
					
					script {				
						echo "CHOICE=${env.CHOICE}"
					    //Terraform plan
						
					    if (env.CHOICE == "Create") {
							if (env.CHECK_OKE == "1") {
								echo "Oke Already Exists"
							}
							else {
								//Ask Question in order to apply terraform plan or not
								def deploy_validation = input(
								id: 'Deploy',
								message: 'Let\'s continue the deploy plan',
								type: "boolean")
								
								sh 'terraform apply -input=false -auto-approve myplan'
								sh 'ls'
							}	
						}
						else {
						    sh 'terraform destroy -input=false -auto-approve'
						}
					}
				}
			}
		}
    }    
}
