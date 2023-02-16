# gitlab-ci.yml

GitLab CI templates and snippets

## terraform

The CI template `terraform/Terraform.gitlab-ci.yml` is based on the [GitLab terraform CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml).

The template modifies the [GitLab terraform CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml) so that the [GitLab flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html#introduction-to-gitlab-flow) can be used (s. example project [GitLab Terraform GitLab Flow](https://gitlab.with.de/try/gitlab-terraform-gitlab-flow)).

The template is based on `terraform/Terraform.base.gitlab-ci.yml` and includes the header yaml and a yaml for each job:

- ['/terraform/Terraform.base.gitlab-ci.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.header.yml)
- ['/terraform/Terraform.gitlab-ci.header.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.header.yml)
- ['/terraform/Terraform.gitlab-ci.job-fmt.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.job-fmt.yml)
- ['/terraform/Terraform.gitlab-ci.job-validate.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.job-validate.yml)
- ['/terraform/Terraform.gitlab-ci.job-build.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.job-build.yml)
- ['/terraform/Terraform.gitlab-ci.job-deploy.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.job-deploy.yml)
- ['/terraform/Terraform.gitlab-ci.job-destroy.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.job-destroy.yml)

The deploy job yaml defines the deploy job extending `.deploy_without_before_script`.
The same pattern is also used for the destroy job.

The CI yaml ['/terraform/Terraform.gitlab-ci.fmt-validate-build.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.gitlab-ci.fmt-validate-build.yml) includes everything but the deploy and the destroy job.

There are a couple of before_scripts that can be used by [reference-tags](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#reference-tags) in ['/terraform/Terraform.base.gitlab-ci.before-scripts.yml'](https://gitlab.with.de/packages-and-registries/gitlab-ci.yml/-/blob/main/terraform/Terraform.base.gitlab-ci.before-scripts.yml).

The simplest usage is

```yaml
include:
  - project: 'packages-and-registries/gitlab-ci.yml'
    file:    '/terraform/Terraform.gitlab-ci.yml'
```

A CI with extra before scripts in the deploy job is the following

```yaml
include:
  - project: 'packages-and-registries/gitlab-ci.yml'
    file:
    - '/terraform/Terraform.base.gitlab-ci.before-scripts-ssh.yml'
    - '/terraform/Terraform.gitlab-ci.fmt-validate-build.yml'
    - '/terraform/Terraform.base.gitlab-ci.job-deploy-without-before-script.yml'
    - '/terraform/Terraform.gitlab-ci.job-destroy.yml'

deploy:
  extends: 
    - .deploy_without_before_script
  before_script:
    - !reference [.before_script_secrets_vars, before_script]
    - !reference [.before_script_ssh_prepare_id, before_script]
    - !reference [.before_script_ssh_agent_add_id, before_script] 
    - !reference [.before_script_ansible_requirements, before_script] 
```

## trivy

The CI snippet `trivy/Trivy.gitlab-ci.yml` is an adapted `Trivy.gitlab-ci.yml` from section "GitLab CI using Trivy container" on [GitLab CI](https://aquasecurity.github.io/trivy/v0.22.0/advanced/integrations/gitlab-ci/).

The HTML and the JSON templates are copied from [aquasecurity/trivy](https://github.com/aquasecurity/trivy/blob/main/contrib/).

The reports are placed in `$CI_PROJECT_DIR/.trivy-reports`.

The full image name has to be placed in `$FULL_IMAGE_NAME`.

The jobs are assigned to stage `scan`.

## vault

The CI snippet `vault/Vault.tools.gitlab-ci.yml` combines all vault CI snippets:

* [vault secrets](#vault-secrets)
* [vault token](#vault-token)
* [vault kv puts](#vault-kv-puts)
* [vault kv2 patches](#vault-kv2-patches)

and puts all shell scripts into artifacts.
Some scripts use [jq](https://stedolan.github.io/jq/) and [jc](https://github.com/kellyjonbrazil/jc) and outputs commands using [vault](https://www.hashicorp.com/products/vault).

The job is assigned to stage `vault_tools_sh`.

If in a job other artifacts are defined, use

```yaml
  dependencies:
    - vault_tools_sh
```

## vault secrets

The CI snippet `vault/Vault.secrets.gitlab-ci.yml` (`vault/Vault.gitlab-ci.yml` is deprecated) puts the shell scripts `vault_secrets.sh` into artifacts.
The script uses [jq](https://stedolan.github.io/jq/) and [jc](https://github.com/kellyjonbrazil/jc) and outputs commands using [vault](https://www.hashicorp.com/products/vault).

The purpose is to simplify fetching secrets from [vault](https://www.hashicorp.com/products/vault).

The job is assigned to stage `vault_secrets_sh`.

If in a job other artifacts are defined, use

```yaml
  dependencies:
    - vault_secrets_sh
```

to ensure fetching `vault_secrets.sh` from artifacts.

The shell script `vault_secrets.sh` interpretes a yaml file describing vault secrets, for instance:

```yaml
secrets:
  - VAULT_AUTH_ROLE: terraform
    SSH_PASSPHRASE:
      path:  gitlab/with_de
      field: ssh_passphrase
    SSH_PRIVATE_KEY:
      path:  gitlab/with_de
      field: ssh_private_key
    TF_VAR_hcloud_token:
      path:  gitlab/with_de
      field: hcloud_token
  - VAULT_AUTH_ROLE: mailcow
    MAILCOW_ADMIN_USER:
      mount: gitlab
      path:  mailcow
      field: mailcow_admin_user
    MAILCOW_ADMIN_PASSWORD:
      mount: gitlab
      path:  mailcow
      field: mailcow_admin_password
    MAILCOW_MAILBOX_PASSWORDS:
      mount:  gitlab
      path:   mailcow/mailbox_passwords
      format: json
```

`path` is mandatory, `mount`, `field` and `format` are optional.

The syntax is closely related to use the `vault kv get` command and related to [Use Vault secrets in a CI job](https://docs.gitlab.com/ee/ci/secrets/index.html#use-vault-secrets-in-a-ci-job) in GitLab Premium.

The usage is

```bash
./vault_secrets.sh <secrets> [option]
```

The script by default outputs the commands to fetch the secrets described in the yaml file `secrets` from vault.

`option` can be

<!-- markdownlint-disable MD033 -->
* `--debug` / `-d` <br /> output the commands to fetch the secrets from vault, do not use sub shell for vault and thus propagate errors
* `--test` / `-t` <br /> output the commands to fetch the secrets from vault, only try fetching secrets from vault, do not export the secrets
* `--markdown` / `-m` <br /> output a markdown table documenting the secrets
<!-- markdownlint-enable MD033 -->

There are two usages:

```bash
./vault_secrets.sh secrets.yml
```

shows the commands produced by `vault_secrets.sh`.

```bash
./vault_secrets.sh secrets.yml >.secrets && . .secrets && rm .secrets
```

executes the commands produced by `vault_secrets.sh` in the execution context.

You have to set `VAULT_ADDR` and possibly `VAULT_CACERT` for using `vault_secrets.sh`.

It is a good pratice to use [YAML anchors for scripts](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#yaml-anchors-for-scripts) by defining in the CI definition

```yaml
.before-script-vault: &before-script-vault
  - ./vault_secrets.sh secrets.yml >.secrets && . .secrets && rm .secrets
```

### Test

You can test if all secrets are accessable by

The CI snippet also puts the shell script `vault_secrets_test.sh` into artifacts.
This script tests if all secrets are accessable.

```bash
./vault_secrets.sh secrets.yml --test >.secrets && . .secrets && rm .secrets
```

### Markdown for vault_secrets

You can output a Markdown table documenting the secrets by

```bash
./vault_secrets.sh secrets.yml --markdown
```

For the secrets yaml example above the result is

| variable | role | path | field |
| --- | --- | --- | --- |
| SSH_PRIVATE_KEY | terraform | gitlab/ssh | ssh_private_key |
| TF_VAR_ssh_key_name | terraform | gitlab/ssh | ssh_key_name |
| DNS_API_TOKEN | terraform | gitlab/dns | dns_api_token |
| APPLICATION_REGISTRY_AUTH | application | gitlab/applications | registry_auth |
| TEST_LONG_PATH | application | gitlab/applications/subfolder | test_long_path |

This output can pasted into the `README.md` of the project for documentation purpose.

## vault token

The CI snippet `vault/Vault.token.gitlab-ci.yml` puts the shell scripts `vault_token.sh` into artifacts.
The script use [vault](https://www.hashicorp.com/products/vault) to fetch a vault token and exports the token.

The purpose is to simplify fetching a vault to token.

The job is assigned to stage `vault_token_sh`.

If in a job other artifacts are defined, use

```yaml
  dependencies:
    - vault_token_sh
```

to ensure fetching `vault_token.sh` from artifacts.

The usage is

```bash
./vault_token.sh <vault-auth-role> [option]
```

The shell script `vault_token.sh` fetches a vault token for the role and exports the token in the environment variable `VAULT_TOKEN`.

It is a good pratice to use [YAML anchors for scripts](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#yaml-anchors-for-scripts) by defining in the CI definition

```yaml
.before-script-vault: &before-script-vault
  - ./vault_token.sh terraform
```

## vault kv puts

The CI snippet `vault/Vault.kv_puts.gitlab-ci.yml` puts the shell scripts `vault_kv_puts.sh` into artifacts.
The script uses [jq](https://stedolan.github.io/jq/) and [jc](https://github.com/kellyjonbrazil/jc) and outputs commands using [vault](https://www.hashicorp.com/products/vault).

The purpose is to simplify putting key value pairs into [vault](https://www.hashicorp.com/products/vault).

The job is assigned to stage `vault_kv_puts_sh`.

If in a job other artifacts are defined, use

```yaml
  dependencies:
    - vault_kv_puts_sh
```

to ensure fetching `vault_kv_puts.sh` from artifacts.

The shell script `vault_kv_puts.sh` interpretes a yaml file describing vault key value pairs, for instance:

```yaml
kv_puts:
  - VAULT_AUTH_ROLE: mailcow
    gitlab/mailcow/kv:
      TLSA_dns_record_value: TLSA_DNS_RECORD_VALUE
      DKIM_dns_record_value: DKIM_DNS_RECORD_VALUE
    gitlab/mailcow/kv2:
      TLSA_dns_record_value2: TLSA_DNS_RECORD_VALUE2
      DKIM_dns_record_value2: DKIM_DNS_RECORD_VALUE2
  - VAULT_AUTH_ROLE: terraform
    gitlab/terraform/kv:
      TOKEN: token
      KEY:   key
    gitlab/terraform/kv2:
      TOKEN2: token2
      KEY2:   key2
```

The usage is

```bash
./vault_kv_puts.sh <vault-auth-role>
```

The script by default outputs the commands to put the key value pairs described in the yaml file `kv_puts` into vault.

`option` can be

<!-- markdownlint-disable MD033 -->
* `--markdown` / `-m` <br /> output a markdown table documenting the key value pairs
<!-- markdownlint-enable MD033 -->

There are two usages:

```bash
./vault_kv_puts.sh kv_puts.yml
```

shows the commands produced by `vault_kv_puts.sh`.

```bash
./vault_kv_puts.sh kv_puts.yml >.kv_puts && . .kv_puts && rm .kv_puts
```

executes the commands produced by `vault_kv_puts.sh` in the execution context.

You have to set `VAULT_ADDR` and possibly `VAULT_CACERT` for using `vault_kv_puts.sh`.

It is a good pratice to use [YAML anchors for scripts](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#yaml-anchors-for-scripts) by defining in the CI definition

```yaml
.after-script-vault: &after-script-vault
  - ./vault_kv_puts.sh kv_puts.yml >.kv_puts && . .kv_puts && rm .kv_puts
```

### Markdown for vault_kv_puts

You can output a Markdown table documenting the secrets by

```bash
./vault_kv_puts.sh kv_puts.yml --markdown
```

For the kv puts yaml example above the result is

| role | path| key | value |
| --- | --- | --- | --- |
| mailcow | gitlab/mailcow/kv | TLSA_dns_record_value | TLSA_DNS_RECORD_VALUE |
| mailcow | gitlab/mailcow/kv | DKIM_dns_record_value | DKIM_DNS_RECORD_VALUE |
| mailcow | gitlab/mailcow/kv2 | TLSA_dns_record_value2 | TLSA_DNS_RECORD_VALUE2 |
| mailcow | gitlab/mailcow/kv2 | DKIM_dns_record_value2 | DKIM_DNS_RECORD_VALUE2 |
| terraform | gitlab/mailcow/kv | TLSA_dns_record_value | TLSA_DNS_RECORD_VALUE |
| terraform | gitlab/mailcow/kv | DKIM_dns_record_value | DKIM_DNS_RECORD_VALUE |
| terraform | gitlab/mailcow/kv2 | TLSA_dns_record_value2 | TLSA_DNS_RECORD_VALUE2 |
| terraform | gitlab/mailcow/kv2 | DKIM_dns_record_value2 | DKIM_DNS_RECORD_VALUE2 |

This output can pasted into the `README.md` of the project for documentation purpose.

## vault kv2 patches

The CI snippet `vault/Vault.kv2_patches.gitlab-ci.yml` puts the shell scripts `vault_kv2_patches.sh` into artifacts.
The script uses [jq](https://stedolan.github.io/jq/) and [jc](https://github.com/kellyjonbrazil/jc) and outputs commands using [vault](https://www.hashicorp.com/products/vault).

The purpose is to simplify putting key value pairs into [vault](https://www.hashicorp.com/products/vault).

The job is assigned to stage `vault_kv2_patches_sh`.

If in a job other artifacts are defined, use

```yaml
  dependencies:
    - vault_kv2_patches_sh
```

to ensure fetching `vault_kv2_patches.sh` from artifacts.

The shell script `vault_kv2_patches.sh` interpretes a yaml file describing vault key value pairs, for instance:

```yaml
kv2_patches:
  - VAULT_AUTH_ROLE: mailcow
    TLSA_DNS_RECORD_VALUE:
      mount: gitlab
      path:  mailcow/kv
      field: TLSA_dns_record_value
    DKIM_DNS_RECORD_VALUE: 
      mount: gitlab
      path:  mailcow/kv
      field: DKIM_dns_record_value
  - VAULT_AUTH_ROLE: terraform
    TOKEN: 
      path:  gitlab/terraform/kv
      field: token
    KEY:
      path:  gitlab/terraform/kv
      field: key
```

`path` and `field` are mandatory, `mount` is optional.

The usage is

```bash
./vault_kv2_patches.sh <vault-auth-role>
```

The script by default outputs the commands to put the key value pairs described in the yaml file `kv2_patches` into vault.

`option` can be

<!-- markdownlint-disable MD033 -->
* `--markdown` / `-m` <br /> output a markdown table documenting the key value pairs
<!-- markdownlint-enable MD033 -->

There are two usages:

```bash
./vault_kv2_patches.sh kv2_patches.yml
```

shows the commands produced by `vault_kv2_patches.sh`.

```bash
./vault_kv2_patches.sh kv2_patches.yml >.kv2_patches && . .kv2_patches && rm .kv2_patches
```

executes the commands produced by `vault_kv2_patches.sh` in the execution context.

You have to set `VAULT_ADDR` and possibly `VAULT_CACERT` for using `vault_kv2_patches.sh`.

It is a good pratice to use [YAML anchors for scripts](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#yaml-anchors-for-scripts) by defining in the CI definition

```yaml
.after-script-vault: &after-script-vault
  - ./vault_kv2_patches.sh kv2_patches.yml >.kv2_patches && . .kv2_patches && rm .kv2_patches
```

### markdown

You can output a Markdown table documenting the secrets by

```bash
./vault_kv2_patches.sh kv2_patches.yml --markdown
```

For the kv2 patches yaml example above the result is

| role | path| key | value |
| --- | --- | --- | --- |
| mailcow | gitlab/mailcow/kv | TLSA_dns_record_value | TLSA_DNS_RECORD_VALUE |
| mailcow | gitlab/mailcow/kv | DKIM_dns_record_value | DKIM_DNS_RECORD_VALUE |
| mailcow | gitlab/mailcow/kv2 | TLSA_dns_record_value2 | TLSA_DNS_RECORD_VALUE2 |
| mailcow | gitlab/mailcow/kv2 | DKIM_dns_record_value2 | DKIM_DNS_RECORD_VALUE2 |
| terraform | gitlab/mailcow/kv | TLSA_dns_record_value | TLSA_DNS_RECORD_VALUE |
| terraform | gitlab/mailcow/kv | DKIM_dns_record_value | DKIM_DNS_RECORD_VALUE |
| terraform | gitlab/mailcow/kv2 | TLSA_dns_record_value2 | TLSA_DNS_RECORD_VALUE2 |
| terraform | gitlab/mailcow/kv2 | DKIM_dns_record_value2 | DKIM_DNS_RECORD_VALUE2 |

This output can pasted into the `README.md` of the project for documentation purpose.
