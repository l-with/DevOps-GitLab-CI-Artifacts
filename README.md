# gitlab-ci.yml

GitLab CI templates and snippets

## trivy

The CI snippet is an adapted `Trivy.gitlab-ci.yml` from section "GitLab CI using Trivy container" on https://aquasecurity.github.io/trivy/v0.22.0/advanced/integrations/gitlab-ci/.

The HTML and the JSON templates are copied from https://github.com/aquasecurity/trivy/blob/main/contrib/.

The reports are placed in `$CI_PROJECT_DIR/.trivy-reports`.

The full image name has to be placed in `$FULL_IMAGE_NAME`.
