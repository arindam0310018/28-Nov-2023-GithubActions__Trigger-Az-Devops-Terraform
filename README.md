# Trigger Az Devops Pipelines and Terraform using Github Actions

Greetings my fellow Technology Advocates and Specialists.

In this Session, I will demonstrate, how to __Trigger Azure Devops Pipelines using Github Actions.__

| __REQUIREMENTS:-__ |
| --------- |

1. Github Repository.
2. Github Actions Workflow.
3. Azure Subscription.
4. Azure Devops Organisation, Project and Pipeline.
5. Azure Devops PAT (Personal Access Token)
6. Service Principal with Required RBAC ( __Contributor__) applied on Subscription or Resource Group(s).
7. Azure Resource Manager Service Connection in Azure DevOps.
8. Microsoft DevLabs Terraform Extension Installed in Azure DevOps.
9. Terraform Code.

| __OUT OF SCOPE:-__ |
| --------- |
| __Terraform Code Snippet Explanation.__ |
| __Azure DevOps Pipeline Code Snippet Explanation.__ |
| __If you are interested to understand Terraform and Pipeline Code, please refer my other blogs in [Terraform](https://dev.to/arindam0310018/series/20638) Series.__ |

| PIPELINE CODE SNIPPET:- | 
| --------- |

| GITHUB ACTIONS YAML WORKFLOW (trigger-az-pipelines.yml):- | 
| --------- |

```
# Github Actions Workflow to Trigger Azure Devops Pipelines to Execute Terraform Code.

name: Trigger Azure Pipelines

# Controls when the workflow will run
on:
  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a job called "build-in-actions-workflow"
  build-in-actions-workflow:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest
    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
    # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
    - uses: actions/checkout@v3

  # This workflow contains a job called "deploy-using-azure-pipelines"
  deploy-using-azure-pipelines:
    # This job is dependent on the previous job "build-in-actions-workflow" 
    needs: build-in-actions-workflow
    # The type of runner that the job will run on
    runs-on: ubuntu-latest
    steps:
    - name: 'Trigger an Azure Pipeline to Register Azure Providers in a Subscription using Terraform'
      uses: Azure/pipelines@releases/v1
      with:
        azure-devops-project-url: 'https://dev.azure.com/ArindamMitra0251/AMCLOUD'
        azure-pipeline-name: 'Az-Provider-Registration' 
        azure-devops-token: '${{ secrets.AZURE_DEVOPS_TOKEN }}'
```

| EXPLANATION:- | 
| --------- |

Below follows the step by step explanation of Github Actions workflow: -

1. Name of the workflow.
```
name: Trigger Azure Pipelines

```

2. We need to Control how the workflow will run. with below, it will allow you to run this workflow manually from the Actions tab.

```
on:
  workflow_dispatch:
```

3. A workflow run is made up of one or more jobs that can run sequentially or in parallel. 

```
jobs:

```

4. The Name of the __first__ job is "build-in-actions-workflow". This Job will run on the runner "ubuntu-latest".

```
  build-in-actions-workflow:
    runs-on: ubuntu-latest
    
```

5. "Steps" represent a sequence of tasks that will be executed as part of the job. "actions/checkout@v3" task Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it.

```
    steps:
    - uses: actions/checkout@v3
```

6. The Name of the __Second__ job is "deploy-using-azure-pipelines". This Job is dependent on the __First__ job "build-in-actions-workflow" and will run on the runner "ubuntu-latest".

```
deploy-using-azure-pipelines: 
    needs: build-in-actions-workflow
    runs-on: ubuntu-latest
```

7. The Name of the "Step" in the __Second Job__ is "Trigger an Azure Pipeline to Register Azure Providers in a Subscription using Terraform". "Azure/pipelines@releases/v1" task is used to trigger Azure Devops Pipelines from Github Actions Workflow. In order to do so, below is required -

| __REQUIREMENTS__ | 
| --------- |
| Azure Devops Project URL | 
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ee2r75fqs0nebecm7h5m.jpg) |
| Azure Pipeline Name | 
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/fjymoerb9oggspadytfi.jpg) |
| Generate PAT in Azure Devops | 
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/b2vev5wmmaw6le1xo4rm.jpg) |
| Store Azure Devops PAT as Github Repository Secret | 
|![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wwf1ocsopjmsiu14s5wk.jpg) |

```
    steps:
    - name: 'Trigger an Azure Pipeline to Register Azure Providers in a Subscription using Terraform'
      uses: Azure/pipelines@releases/v1
      with:
        azure-devops-project-url: 'https://dev.azure.com/ArindamMitra0251/AMCLOUD'
        azure-pipeline-name: 'Az-Provider-Registration' 
        azure-devops-token: '${{ secrets.AZURE_DEVOPS_TOKEN }}'
```
| __NOTE:-__ |
| --------- |
| 1. All the below YAML (Pipeline) and Terraform codes resides in Azure Devops Project repository. |
| 2. The explanation of the YAML (Pipeline) and Terraform codes are out of scope as mentioned above. |

| AZURE DEVOPS YAML PIPELINE (azure-pipelines-az-resource-provider-registration-v1.0.yml):- |
| --------- |

```
trigger:
  none

######################
#DECLARE PARAMETERS:-
######################
parameters:
- name: SubscriptionID
  displayName: Subscription ID Details Follow Below:-
  default: 210e66cb-55cf-424e-8daa-6cad804ab604
  values:
  -  210e66cb-55cf-424e-8daa-6cad804ab604

- name: ServiceConnection
  displayName: Service Connection Name Follows Below:-
  default: amcloud-cicd-service-connection
  values:
  -  amcloud-cicd-service-connection

######################
#DECLARE VARIABLES:-
######################
variables:
  TfVars: "az-resource-provider-registration.tfvars"
  PlanOutput: "azresourceprovidertfplan"
  ResourceGroup: "tfpipeline-rg"
  StorageAccount: "tfpipelinesa"
  Container: "terraform"
  TfstateFile: "ResourceProviderRegistration/registerresourceprovders.tfstate"  
  BuildAgent: "windows-latest"
  WorkingDir: "$(System.DefaultWorkingDirectory)/Resource-Provider-Registration"
  Target: "$(build.artifactstagingdirectory)/AMTF"
  Environment: "NonProd"
  Artifact: "AM"

#########################
# Declare Build Agents:-
#########################
pool:
  vmImage: $(BuildAgent)

###################
# Declare Stages:-
###################
stages:

- stage: PLAN
  jobs:
  - job: PLAN
    displayName: PLAN
    steps:
# Install Terraform Installer in the Build Agent:-
    - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
      displayName: INSTALL TERRAFORM VERSION - LATEST
      inputs:
        terraformVersion: 'latest'
# Terraform Init:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM INIT
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(workingDir)' # Az DevOps can find the required Terraform code
        backendServiceArm: '${{ parameters.ServiceConnection }}' 
        backendAzureRmResourceGroupName: '$(ResourceGroup)' 
        backendAzureRmStorageAccountName: '$(StorageAccount)'
        backendAzureRmContainerName: '$(Container)'
        backendAzureRmKey: '$(TfstateFile)'
# Terraform Validate:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM VALIDATE
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(workingDir)'
        environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'
# Terraform Plan:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM PLAN
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(workingDir)'
        commandOptions: "--var-file=$(TfVars) --out=$(PlanOutput)"
        environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'
    
# Copy Files to Artifacts Staging Directory:-
    - task: CopyFiles@2
      displayName: COPY FILES ARTIFACTS STAGING DIRECTORY
      inputs:
        SourceFolder: '$(workingDir)'
        Contents: |
          **/*.tf
          **/*.tfvars
          **/*tfplan*
        TargetFolder: '$(Target)'
# Publish Artifacts:-
    - task: PublishBuildArtifacts@1
      displayName: PUBLISH ARTIFACTS
      inputs:
        targetPath: '$(Target)'
        artifactName: '$(Artifact)' 

- stage: DEPLOY
  condition: succeeded()
  dependsOn: PLAN
  jobs:
  - deployment: 
    displayName: Deploy
    environment: $(Environment)
    pool:
      vmImage: '$(BuildAgent)'
    strategy:
      runOnce:
        deploy:
          steps:
# Download Artifacts:-
          - task: DownloadBuildArtifacts@0
            displayName: DOWNLOAD ARTIFACTS
            inputs:
              buildType: 'current'
              downloadType: 'single'
              artifactName: '$(Artifact)'
              downloadPath: '$(System.ArtifactsDirectory)' 
# Install Terraform Installer in the Build Agent:-
          - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
            displayName: INSTALL TERRAFORM VERSION - LATEST
            inputs:
              terraformVersion: 'latest'
# Terraform Init:-
          - task: TerraformTaskV2@2 
            displayName: TERRAFORM INIT
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF/' # Az DevOps can find the required Terraform code
              backendServiceArm: '${{ parameters.ServiceConnection }}' 
              backendAzureRmResourceGroupName: '$(ResourceGroup)' 
              backendAzureRmStorageAccountName: '$(StorageAccount)'
              backendAzureRmContainerName: '$(Container)'
              backendAzureRmKey: '$(TfstateFile)'
# Terraform Apply:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM APPLY # The terraform Plan stored earlier is used here to apply only the changes.
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF'
              commandOptions: '--var-file=$(TfVars)' # The terraform Plan stored earlier is used here to apply. 
              environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'

```

| TERRAFORM CODE SNIPPET:- | 
| --------- |

| TERRAFORM (main.tf):- | 
| --------- |

```
terraform {

  required_version = ">= 1.3.3"
  
  backend "azurerm" {
    resource_group_name  = "tfpipeline-rg"
    storage_account_name = "tfpipelinesa"
    container_name       = "terraform"
    key                  = "ResourceProviderRegistration/registerresourceprovders.tfstate"
  }

}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

```

| TERRAFORM (az-resource-provider-registration.tf):- | 
| --------- |

```
#####################################
## Resource Provider Registration:-
#####################################

resource "azurerm_resource_provider_registration" "az-resource-provider-register" {
  count   = var.create-az-resource-provider-names == true ? length(var.az-resource-provider-names) : 0
  name    = var.az-resource-provider-names[count.index] 
}

```

| TERRAFORM (variables.tf):- | 
| --------- |

```
variable "create-az-resource-provider-names" {
  type        = bool
  description = "Specifies whether Azure Resource Providers should be Registered."
}

variable "az-resource-provider-names" {
  type        = list(string)
  description = "List of Azure Resource Providers."
}

```

| TERRAFORM (az-resource-provider-registration.tfvars):- | 
| --------- |

```
create-az-resource-provider-names = true

az-resource-provider-names  = [
    "Microsoft.Elastic", 
    "Microsoft.ElasticSan", 
    "Microsoft.AAD", 
    "Microsoft.AppConfiguration", 
    "Microsoft.Batch",
    "Microsoft.Cloudshell",
    "Microsoft.Confluent",
    "Microsoft.CostManagementExports",
    "Microsoft.DataFactory",
    "Microsoft.EntitlementManagement",
    "Microsoft.Fabric",
    "Microsoft.Kubernetes",
    "Microsoft.KubernetesConfiguration",
    "Microsoft.Monitor",
    "Microsoft.PowerBI",
    "Microsoft.Purview",
    "Microsoft.SignalRService",
    "Microsoft.SqlVirtualMachine",
    "Microsoft.Synapse"
]
```

| TEST RESULTS:- | 
| --------- |
| 1. Manually Run Github Actions Workflow. |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/dlto1rc7oiwpf085uvhg.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/rxow3nr0gvye69a55yih.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xahfv5ewgbri88f8ue2b.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/bnbikxu8aynsbibcslcm.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/yjoefyt71pnvfhjxwqxn.jpg) |
| 2. Azure Devops Pipeline will then be triggered. |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ach96pdgg5d4pzqrjdt6.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/35wj93niu247g7qufcty.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cinsythu2l3qo996seo1.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7rtygqbaunkiy335uhhi.jpg) |

__Hope You Enjoyed the Session!!!__

__Stay Safe | Keep Learning | Spread Knowledge__
