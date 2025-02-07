# CloudTrack - Infrastructure

## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Setup](#setup)
* [Repositories](#repositories)

## General info
CloudTrack is an example application to support run competitions.
This repository contains infrastructure described in Azure Bicep templates. In the repo is a GitHub Actions workflow included which is responsible for create the infrastructure in Azure cloud.

## Technologies
Project is created with:
* Bicep
	
## Setup
To run this project from GitHub Actions:
* Create dedicated service principal in Azure and grab the result of it

```
az ad sp create-for-rbac --name "cloudtrack-github-actions" --role owner --scopes /subscriptions/{subscriptions-id}
```

* Define GitHub Actions secret named AZURE_CREDENTIALS and put there the value from the previous step

* Define GitHub Actions secret named AZURE_SUBSCRIPTION and put there the id of your Azure Subscription

* Define GitHub Actions secret named DB_ADMIN_LOGIN and put there your database username

* Define GitHub Actions secret named DB_ADMIN_PASSWORD and put there your database password

* Define GitHub Actions variable named AZURE_LOCATION and put there correct name of Azure region where do you want to deploy your resources

* Define GitHub Actions variable named AZURE_GROUP and put there correct name of Azure resource group name where do you want to deploy your resources

* Run GitHub workflow and pass the name of environment (dev, uat, prod)

## Repositories
* Infrastructure: [github.com/beniaminzaborski/cloudtrack-infra](https://github.com/beniaminzaborski/cloudtrack-infra)
* API Gateway: [github.com/beniaminzaborski/cloudtrack-apigw](https://github.com/beniaminzaborski/cloudtrack-apigw)
* Competitions: [github.com/beniaminzaborski/cloudtrack-compet](https://github.com/beniaminzaborski/cloudtrack-compet)
* Registration: [github.com/beniaminzaborski/cloudtrack-regstr](https://github.com/beniaminzaborski/cloudtrack-regstr)
