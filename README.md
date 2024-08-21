# Rabobank Assignment
In this project, you will find my initial setup for a Rabobank assignment. The assignment can be found in `assignment/Assignment.pdf`.

## Dependencies
- Python 3.12
- Java

## Notes
Rabobank assignment received through email. In `assignment`, the assignment pdf can be found with the data. The records CSV file is a simplified version in [MT940 format](https://en.wikipedia.org/wiki/MT940).
 
## Project Structure
```shell
.
├── api/                                # a simple FastAPI solution
├── assignment/                         # the original assignment
├── azurite/                            # initialisation of Azurite blobs
├── notebooks/                          # Spark notebook for running validation checks
├── postgresql/                         # initialisation of PostgreSQL tables
├── terraform/                          # Terraform code for deploying Azure resources
├── docker-compose.yml
├── Makefile
├── README.md
└── requirements.txt
```

## Project Setup
Due to Azure Sandbox limitations this project contains local deployments for storage solutions, such as Azurite and Postgresql. Furthermore, it contains a notebook to run the PySpark commands and an API for retrieving the failed records.

To setup the initial project run:
```
make setup
make validate
```

This will install the `requirements.txt` file and run Azurite, PostgreSQL and the [FastAPI](https://fastapi.tiangolo.com) found in the Docker Compose file. Afterwards, the Jupyter Notebook can be executed to insert the `records 1.csv` into the Postgres tables. Finally, the invalid records can be retrieved using the API.

Go to `http://127.0.0.1:8000/docs` to see the API spec. Or retrieve the invalid records from `http://127.0.0.1:8000/records/invalid`.

When you're finished reviewing the records make sure to exit all processes, using `make teardown`, this will stop all containers and remove the related images.

## Initial Plan
1. Create infrastructure using Terraform
    - Deploy Storage Account, Azure SQL Server and Azure Synapse (with Spark Pool)
    - Deploy extra/optional Azure Key Vault for storing admin passwords
2. Upload `records 1.csv` to Storage Account
3. Create table `records` in database with following schema:
    - `transaction_reference` as integer primary key
    - `account_number` as varchar
    - `description` as varchar
    - `start_balance` as float
    - `mutation` as float
    - `end_balance` as float
4. Create Test PySpark pipeline for testing validations on fake table?
    - Insert one succesful record
    - Insert one failed record (non-unique key)
    - Insert one failed record (incorrect end balance)
5. Create PySpark pipeline in Azure Synapse
    - Read CSV from Storage Account
    - Do validation on end balance
    - Insert into table
    - Record failed inserts due to non-unique transaction reference
6. Create simple API to retrieve failed records from database

## Limitations and Considerations
In the end I was not able to follow through on the initial plan due to some limitations of the Azure Sandbox that I have used. In the following section I will go through each implementation I have done for some explanation and further development.

### Api
- Super simple API created with FastAPI with one endpoint. Could add parameters for limited number of invalid records received. Or query parameters based on reference number.

- To run the FastAPI or any kind of API to retrieve records from a database, I would compare any of the following solutions: https://learn.microsoft.com/en-us/azure/container-apps/compare-options. My preference would go to Kubernetes, seeing as it is a cloud agnostic framework for orchestrating containerized workloads, but if the team wants to have less maintenance, I would consider a PoC with either Azure Functions or Azure Container Apps.

- It was my first experience using FastAPI, it was very easy to setup an initial API, however I am unsure whether it is suitable for production usecases.

- Could have done multi-stage building for FastAPI to create slimmer image.

### Notebook
- In the end, I did not use an Azure Synapse Pipeline to do the validations, therefore I used Jupyter Notebooks (with Spark configured) and DuckDB to perform the necessary actions to simulate database upserts.

- I would consider adding a [Storage Event trigger](https://learn.microsoft.com/en-us/azure/data-factory/how-to-create-event-trigger?tabs=data-factory) to the pipeline. Furthermore, regarding pipeline definitions and notebooks I would store these in a Git repository, giving the possibility for CI/CD.

- Connection to Azurite from local Spark configuration seems more complex than initially thought, therefore I opted for using the csv file as is. Although this will be easier when using a Spark notebook in Azure Synapse as the Spark configuration has been set properly.

- Spark writes with JDBC are limited, have to manually write up inserts with constraints, such as primary keys.

### Terraform
- Due to limited permissions on A Cloud Guru Azure Sandbox environment I was unable to perform the following actions:
    - Deploy infrastructure via Terraform
    - Create a Spark Pool in Azure Synapse
    - Unable to connect to Azure SQL Database

- I am not certain the Terraform code will deploy, because I was not able to test it.

- I did not implement any networking on the Azure Resources, although I do expect some networking to be involved when deploying the actual infrastructure.

- I did not [setup a remote state storage account](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=terraform) to store the Terraform state file in Azure as well, should be done too, because we do not want local statefiles.

- An alternative platform would be using Azure Storage Account and Azure Databricks for Engineer workflows, [DBT](https://www.getdbt.com) can be run from Databricks clusters using Databricks workflows.

### CI/CD
- Regarding testing/developing/maintaining all the code, I would have created separate environments. Using Azure Pipelines we can easily integrate some linting, testing and security scanning on all repositories. I would have separated the API, Synapse Pipelines and Terraform into different repositories.

- For Terraform, I would consider [tflint](https://github.com/terraform-linters/tflint) and [tfsec](https://github.com/aquasecurity/tfsec).

- For Azure Synapse Pipelines, I am not quite sure about CI/CD, but would probably have separate workspaces for Development and Production.

- For FastAPI, I would consider creating Azure Pipelines that performs linting, tests and security scanning as well, such as [Ruff](https://github.com/astral-sh/ruff) for linting and [Snyk](https://snyk.io/product/open-source-security-management/) for security scanning. Furthermore, after performing the previous steps building and pushing to Container Registry will be done. 