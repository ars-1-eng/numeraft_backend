plugin "terraform" {
enabled = true
preset = "recommended"
}
plugin "aws" {
enabled = true
version = "0.44.0"
source = "github.com/terraform-linters/tflint-ruleset-aws"
}
rule "terraform_naming_convention" {
enabled = true
format = "snake_case"
}
# Would have caught the missing prod variables.
rule "terraform_documented_variables" {
enabled = true
}
rule "terraform_documented_outputs" {
enabled = true
}
# Would have caught the junk `other` output.
rule "terraform_unused_declarations" {
enabled = true
}
rule "terraform_required_version" {
enabled = true
}
rule "terraform_required_providers" {
enabled = true
}