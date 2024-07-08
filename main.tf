data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "Lambda" {
  source     = "./modules/lambda"
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

module "Codebuild" {
  source = "./modules/codebuild"
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id


}