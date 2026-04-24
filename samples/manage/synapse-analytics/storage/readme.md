# Deploy Azure Storage account for Synapse workspace

This template deploys configured Azure Storage account for Synapse workspace.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2Fsql-server-samples%2Fmaster%2Fsamples%2Fmanage%2Fsynapse-analytics%2Fstorage%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2Fsql-server-samples%2Fmaster%2Fsamples%2Fmanage%2Fsynapse-analytics%2Fstorage%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png"/>
</a>

Select subscription, create resorce group (or use existing one), and put storage account name:
![Deploy storage](media/create-synapse-storage-template.png)

When you create storage, use [this link](https://portal.azure.com/?feature.customportal=false&feature.canmodifystamps=true&SqlAzureExtension=synapse&microsoft_azure_synapse_assettypeoptions=%7B%22SynapseWorkspace%22%3A%7B%22options%22%3A%22%22%7D%2C%22SparkPool%22%3A%7B%22options%22%3A%22hideassettype%22%7D%7D&microsoft_azure_marketplace_ItemHideKey=SynapseExtensionPreview#blade/Microsoft_Azure_Marketplace/MarketplaceOffersBlade/selectedMenuItemId/home/searchQuery/Azure%2BSynapse%2BAnalytics%2B(preview)
) to create Azure Synapse Analytics workspace **(not former DataWarehouse)** and assign the Azure Storage account created with this template.

`Tags: Azure, Synapse, Storage`
