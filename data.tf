############################################################
# Read the pre-built Lambda zip file from local disk.
############################################################

data "local_file" "lambda_zip" {
  filename = "${path.module}/${var.zipfile}"
}

############################################################
# Load Gremlin sensitive credentials from local files.
############################################################

data "local_file" "gremlin_team_id" {
  filename = var.gremlin_team_id_path
}

data "local_sensitive_file" "gremlin_team_certificate" {
  filename = var.gremlin_team_certificate_path
}

data "local_sensitive_file" "gremlin_team_private_key" {
  filename = var.gremlin_team_private_key_path
}

