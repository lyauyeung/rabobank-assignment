.PHONY: setup
setup:
	pip install -r requirements.txt
	docker compose up -d
	python ./azurite/init_azurite.py

.PHONY: validate
validate:
	jupyter execute ./notebooks/validated_records.ipynb

.PHONY: teardown
teardown:
	docker compose down --rmi "all"

