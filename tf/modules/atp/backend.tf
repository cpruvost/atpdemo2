terraform {
  backend "http" {
    address = "https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/r2849V7j7r4WNhWkT24TOk8BRX7GUe4WfQUfPCPxh3E/n/oraseemeafrtech1/b/AtpDemo2/o/terraform.tfstate"
    update_method = "PUT"
  }
}