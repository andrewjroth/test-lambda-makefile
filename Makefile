VENV = venv
PYTHON = $(VENV)/bin/python3
PIP = $(VENV)/bin/pip
STACK_NAME = "test-lambda-deploy"
S3BUCKET = $(shell jq '.[] | select(.ParameterKey == "DeployBucket") | .ParameterValue' cf-params.json)
S3KEY = $(shell jq '.[] | select(.ParameterKey == "DeployKey") | .ParameterValue' cf-params.json)
FUNC_NAME = $(shell aws cloudformation describe-stack-resources --stack-name $(STACK_NAME) \
	--logical-resource-id ScriptFunction --query 'StackResources[0].PhysicalResourceId')

.PHONY: venv run upload deploy update destroy clean

venv: $(VENV)/bin/activate
$(VENV)/bin/activate: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install -U pip
	$(PIP) install -r requirements.txt

run: $(VENV)/bin/activate
	$(PYTHON) main.py

package.zip: $(VENV)/bin/activate *.py
	cd $(wildcard $(VENV)/lib/python*)/site-packages && zip -r ../../../../package.zip .
	zip package.zip ./*.py

upload: package.zip cf-params.json
	aws s3 cp package.zip s3://$(S3BUCKET)/$(S3KEY)

deploy: upload cf-params.json cf-template.yml
	aws cloudformation create-stack --stack-name $(STACK_NAME) --template-body file://cf-template.yml \
		--capabilities CAPABILITY_NAMED_IAM --parameters file://cf-params.json \
		|| aws cloudformation update-stack --stack-name $(STACK_NAME) --template-body file://cf-template.yml \
		--capabilities CAPABILITY_NAMED_IAM --parameters file://cf-params.json

update: upload
	aws --no-cli-pager lambda update-function-code --function-name $(FUNC_NAME) \
		--s3-bucket $(S3BUCKET) --s3-key $(S3KEY)

destroy:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)

clean:
	rm -rf __pycache__
	rm -rf $(VENV)
	rm -f package.zip

