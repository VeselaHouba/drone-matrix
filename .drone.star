def main(ctx):
  oses = [
    "debian-10",
    "ubuntu-18.04",
    "ubuntu-20.04"
  ]

  pipelines = [
    step_lint(),
  ]
  # generate pipelines for hetzner os tests
  for os in oses:
    pipelines.append(step_hetzner(os))
  # publish pipeline with molecule as dependencies
  if ctx.build.event == "tag":
    pipelines.append(step_publish(oses))
  return pipelines

def step_lint():
  return {
    "kind": "pipeline",
    "name": "linter",
    "steps": [
      {
        "name": "Lint",
        "image": "veselahouba/molecule",
        "commands": [
          "shellcheck_wrapper",
          "flake8",
          "yamllint .",
          "ansible-lint"
        ]
      }
    ]
  }

def step_hetzner(os):
  return {
    "kind": "pipeline",
    "depends_on": [
        "linter",
    ],
    "name": "molecule-%s" % os,
    "steps": [
      {
        "name": "Lint",
        "image": "veselahouba/molecule",
        "commands": [
          "shellcheck_wrapper",
          "flake8",
          "yamllint .",
          "ansible-lint"
        ]
      },
      {
        "name": "Molecule test",
        "image": "veselahouba/molecule",
        "environment": {
          "HCLOUD_TOKEN": {
            "from_secret": "HCLOUD_TOKEN"
          }
        },
        "commands": [
          "ansible --version",
          "molecule --version",
          "REF=$$(echo $DRONE_COMMIT_REF | awk -F'/' '{print $$3}'|sed 's/_/-/g')",
          "REPO_NAME=$$(echo $DRONE_REPO_NAME | sed 's/_/-/g')",
          "MOLECULE_IMAGE=%s" % os,
          "export MOLECULE_IMAGE REPO_NAME REF",
          "molecule test --all"
        ]
      }
    ]
  }

def step_publish(oses):
  deps = []
  for os in oses:
    deps.append("molecule-%s" % os)
  return {
    "kind": "pipeline",
    "depends_on": deps,
    "name": "publish",
    "steps": [
        {
          "name": "Publish to Galaxy",
          "image": "veselahouba/molecule",
          "environment": {
            "GALAXY_API_KEY": {
              "from_secret": "GALAXY_API_KEY"
            }
          },
          "commands": [
            "ansible-galaxy role import --api-key $${GALAXY_API_KEY} $${DRONE_REPO_OWNER} $${DRONE_REPO_NAME}"
          ]
        },
        {
          "name": "Slack notification",
          "image": "plugins/slack",
          "settings": {
            "webhook": {
              "from_secret": "slack_webhook"
            },
            "channel": "ci-cd",
            "template":
              "{{#success build.status}}" +
                  "Publish for `{{build.tag}}` succeeded." +
                  "{{build.link}}" +
                "{{else}}" +
                  "Publish for `{{build.tag}}` failed." +
                  "{{build.link}}"+
              "{{/success}}"
          },
          "when": {
            "status": [
              "success",
              "failure"
            ]
          }
        }
    ]
  }
