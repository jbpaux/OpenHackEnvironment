# OpenHack Container - Automated development VM

I've been invited to participate to MS OpenHack training about Containers/Kubernetes.
I've needed to setup a development environment to run the different needed tools but was unable to do it locally.
As always I prefer automation over manual VM configuration so I've created this ARM template and DSC script to deploy all needed components.

## Deploy the template

Quick method:

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjbpaux%2FOpenHackEnvironment%2Fmaster%2Fazuredeploy.json)  [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fjbpaux%2FOpenHackEnvironment%2Fmaster%2Fazuredeploy.json)


Manual method:

* Create a azuredeploy.parameters.json file containing the required parameters or pass them directly
* Launch Deploy-AzTemplate.ps1 script with these parameters : -UploadArtifacts -BuildDscPackage -ResourceGroupLocation westeurope -ResourceGroupName "OpenHackEnvironment"

## Contributing

Don't hesitate to send PR, Issues etc.
