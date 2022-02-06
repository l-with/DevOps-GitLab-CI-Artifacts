# gitlab-ci.yml

GitLab CI templates and snippets

## trivy

The CI snippet is an adapted `Trivy.gitlab-ci.yml` from section "GitLab CI using Trivy container" on [GitLab CI](https://aquasecurity.github.io/trivy/v0.22.0/advanced/integrations/gitlab-ci/).

The HTML and the JSON templates are copied from [aquasecurity/trivy](https://github.com/aquasecurity/trivy/blob/main/contrib/).

The reports are placed in `$CI_PROJECT_DIR/.trivy-reports`.

The full image name has to be placed in `$FULL_IMAGE_NAME`.

The jobs are assigned to stage `scan`.

## vault

The CI snippet puts the shell script `vault_secrets.sh` into artifacts.

The 
If in a job other artifacts are defined, use

```yaml
  dependencies:
    - vault_secrets_sh
```

to ensure fetching `vault_secrets.sh` from artifacts.

The job is assigned to stage `vault_secrets_sh`.

The shell script `vault_secrets.sh` interpretes a yaml file describing vault secrets, for instance:

```yaml
secrets:
  - VAULT_AUTH_ROLE: terraform
    SSH_PRIVATE_KEY:
      vault: ssh/ssh_private_key@gitlab
    TF_VAR_ssh_key_name:
      vault: ssh/ssh_key_name@gitlab
    DNS_API_TOKEN:
      vault: dns/dns_api_token@gitlab
  - VAULT_AUTH_ROLE: application
    APPLICATION_REGISTRY_AUTH:
      vault: applications/registry_auth@gitlab
    TEST_LONG_PATH:
      vault: applications/subfolder/test_long_path@gitlab    
```

The syntax is closely related to [Use Vault secrets in a CI job](https://docs.gitlab.com/ee/ci/secrets/index.html#use-vault-secrets-in-a-ci-job) in GitLab Premium.

There are two usages:

```bash
./vault_secrets secrets.yml
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
