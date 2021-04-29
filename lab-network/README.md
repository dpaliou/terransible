<h2>Deploy VPC, Internet Gateway, Subnets </h2>

<h3>Create S3 bucket</h3>
$ aws s3api create-bucket --bucket dpaliouterrabucket --create-bucket-configuration LocationConstraint=eu-west-2

<h3>Retrieve terraformstatefile (json)</h3>
$ aws s3 cp s3://dpaliouterrabucket/terraformstatefile .