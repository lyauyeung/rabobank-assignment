from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import ResourceExistsError

def main():
    blob_client = BlobServiceClient(
        account_url="http://localhost:10000/devstoreaccount1",
        credential={
            "account_name": "devstoreaccount1",
            "account_key": "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
        }
    )

    container_client = blob_client.get_container_client("records")
    try:
        container_client.create_container()
    except ResourceExistsError:
        print("records container exists")

    with open("./assignment/records 1.csv", "rb") as data:
        container_client.upload_blob(name="records 1.csv", data=data)


if __name__ == "__main__":
    main()