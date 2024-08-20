# Rabobank Assignment
Rabobank assignment.

## Dependencies
- Python 3.12
- Java

## Notes
Rabobank assignment received through email. In `assignment`, the assignment pdf can be found with the data. The records CSV file is a simplified version in [MT940 format](https://en.wikipedia.org/wiki/MT940).
 
## Project Structure
```shell
.
├── api
├── assignment
├── database
├── pipeline
├── terraform
└── README.md
```

### Api
The `api` directory contains a simple API created with [FastAPI](https://fastapi.tiangolo.com) to retrieve failed records from the database.

#### Usage
```
pip install "fastapi[standard]"
pip install duckdb
pip install tabulate

fastapi dev /api/main.py
```

Go to `http://127.0.0.1:8000/docs` to see the API spec. Or retrieve the invalid records from `http://127.0.0.1:8000/records/invalid`.

### Assignment
The `assignment` directory contains the original assignment received from Rabobank.

### Database
The `database` directory contains the [DuckDB](https://duckdb.org) database used containg two tables `validated_records` and `invalid_records`.

`validated_records` schema
| column         | type                  |
|----------------|-----------------------|
| reference      | INTEGER (PRIMARY KEY) |
| account_number | VARCHAR               |
| description    | VARCHAR               |
| start_balance  | FLOAT                 |
| mutation       | FLOAT                 |
| end_balance    | FLOAT                 |

`invalid_records` schema
| column         | type    |
|----------------|---------|
| reference      | INTEGER |
| account_number | VARCHAR |
| description    | VARCHAR |
| start_balance  | FLOAT   |
| mutation       | FLOAT   |
| end_balance    | FLOAT   |

### Pipeline
The `pipeline` directory contains two Jupyter Notebooks. `init_duckdb.ipynb` initialises a `records.db` found in `database` directory. `validated_records.ipynb` contains the PySpark code where the validations are done on the `records 1.csv` file.

### Terraform
The `terraform` directory contains the Terraform code to deploy the following Azure Resources: Azure Key Vault, Azure Storage Account, Azure SQL Database and Azure Synapse Analytics.

## Plan of Attack
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

### Api
- Super simple API created with FastAPI with one endpoint. Could add parameters for limited number of invalid records received. Or query parameters based on reference number.

- Could have created some setup instead of separate `pip install` rows using Poetry.

- To run the FastAPI or any kind of API to retrieve records from a database, I would compare any of the following solutions: https://learn.microsoft.com/en-us/azure/container-apps/compare-options. My preference would go to Kubernetes, seeing as it is a cloud agnostic framework for orchestrating containerized workloads, but if the team wants to have less maintenance, I would consider a PoC with either Azure Functions or Azure Container Apps.

- It was my first experience using FastAPI, it was very easy to setup an initial API, however I am unsure whether it is suitable for production usecases.

### Pipeline
- In the end, I did not use an Azure Synapse Pipeline to do the validations, therefore I used Jupyter Notebooks (with Spark configured) and DuckDB to perform the necessary actions to simulate database upserts.

- Unable to use [ON CONFLICT](https://duckdb.org/docs/sql/statements/insert.html#on-conflict-clause) properly to insert rows into a different table. Unfortunately, DuckDB does not allow triggers (unlike PostgreSQL).

- I would consider adding a [Storage Event trigger](https://learn.microsoft.com/en-us/azure/data-factory/how-to-create-event-trigger?tabs=data-factory) to the pipeline. Furthermore, regarding pipeline definitions and notebooks I would store these in a Git repository, giving the possibility for CI/CD.

- It was my first time using DuckDB to create a quick database instance to perform SQL operations. It is quite fast for these small usecases. DuckDB offers various [extensions](https://duckdb.org/docs/extensions/overview) which makes it easy to connect to different databases.

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