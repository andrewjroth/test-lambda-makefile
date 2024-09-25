VENV = venv
PYTHON = $(VENV)/bin/python3
PIP = $(VENV)/bin/pip
STACK_NAME = "test-lambda-deploy"
S3BUCKET = $(shell jq '.[] | select(.ParameterKey == "DeployBucket") | .ParameterValue' cf-params.json)
S3KEY = $(shell jq '.[] | select(.ParameterKey == "DeployKey") | .ParameterValue' cf-params.json)
FUNC_NAME = $(shell aws cloudformation describe-stack-resources --stack-name $(STACK_NAME) \
	--logical-resource-id ScriptFunction --query 'StackResources[0].PhysicalResourceId')

.PHONY: venv run upload deploy update destroy clean

# Default target: create the virtual environment for Python
venv: $(VENV)/bin/activate
$(VENV)/bin/activate: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install -U pip
	$(PIP) install -r requirements.txt

# Run the main script
run: $(VENV)/bin/activate
	$(PYTHON) main.py

# Create the deployment package containing the dependancies and any ".py" files
package.zip: $(VENV)/bin/activate *.py
	cd $(wildcard $(VENV)/lib/python*)/site-packages && zip -r ../../../../package.zip .
	zip package.zip ./*.py

# Upload the deployment package to S3
upload: package.zip cf-params.json
	aws s3 cp package.zip s3://$(S3BUCKET)/$(S3KEY)

# Deploy the CloudFormation Stack to create the function (and other resources)
deploy: upload cf-params.json cf-template.yml
	aws cloudformation create-stack --stack-name $(STACK_NAME) --template-body file://cf-template.yml \
		--capabilities CAPABILITY_NAMED_IAM --parameters file://cf-params.json \
		|| aws cloudformation update-stack --stack-name $(STACK_NAME) --template-body file://cf-template.yml \
		--capabilities CAPABILITY_NAMED_IAM --parameters file://cf-params.json

# Update the code for an existing function
update: upload
	aws --no-cli-pager lambda update-function-code --function-name $(FUNC_NAME) \
		--s3-bucket $(S3BUCKET) --s3-key $(S3KEY)

# Delete the CloudFormation Stack containing the function (and other resources)
destroy:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)

# Remove local build files
clean:
	rm -rf __pycache__
	rm -rf $(VENV)
	rm -f package.zip

