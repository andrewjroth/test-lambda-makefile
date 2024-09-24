# test-lambda-makefile

A test of managing an AWS Lambda project using Makefile

Rename or copy the `cf-params-template.json` file to `cf-params.json`
and fill in the values correctly for your environment.  
Also, review the Makefile to configure the `STACK_NAME` variable used
for the CloudFormation Stack.

This follows the packaging and deployment guidelines outlined by AWS in:  
[Creating a .zip deployment package with dependencies][python-package]

[python-package]: https://docs.aws.amazon.com/lambda/latest/dg/python-package.html#python-package-create-dependencies

