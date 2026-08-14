locals {
  # "GET /reports/{reportId}" becomes { method = "GET", path = "/reports/*" }.
  # Path parameters must be wildcards in a Lambda permission source ARN.
  route_parts = {
    for key, cfg in var.routes : key => {
      method = split(" ", key)[0]
      path   = replace(split(" ", key)[1], "/\\{[^}]+\\}/", "*")
    }
  }
}