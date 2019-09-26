# Metadata Resource
[![Build Status](https://travis-ci.org/olhtbr/metadata-resource.svg?branch=master)](https://travis-ci.org/olhtbr/metadata-resource)

This resource outputs [Concourse.ci](http://concourse.ci/) [build metadata](http://concourse.ci/implementing-resources.html#resource-metadata)
to files to make annotations easier. One such use-case may be to add build links to the [body](https://github.com/concourse/github-release-resource#out-publish-a-release) of GitHub releases.

As Concourse [documentation](http://concourse.ci/implementing-resources.html#resource-metadata) states, **avoid using this for versioning**. Use the [semver resource](https://github.com/concourse/semver-resource) instead.

## Behavior
:warning: Since 2.0.0 a **put** step has to used instead of a get to fix [this issue](https://github.com/olhtbr/metadata-resource/issues/1). If you want the old behaviour, use version 1.0.0 of this resource. :warning:

### `check`: Not used
Always emits an empty version.

### `in`: Output metadata to files
Outputs `$BUILD_ID`, `$BUILD_NAME`, `$BUILD_JOB_NAME`, `$BUILD_PIPELINE_NAME`, `$BUILD_TEAM_NAME` and `$ATC_EXTERNAL_URL` to files `build_id`, `build_name`, `build_job_name`, `build_pipeline_name`, `build_team_name` and `atc_external_url` respectively.

### `out`: Not used

## Example
The following example shows how a GitHub release can be created with a link pointing to the build.

```yaml
# Register the metadata resource type
resource_types:
  - name: metadata
    type: docker-image
    source:
      repository: olhtbr/metadata-resource
      tag: 2.0.1

resources:
  # The resource does not need any configuration
  - name: metadata
    type: metadata

  # GitHub release resource
  # Check https://github.com/concourse/github-release-resource#source-configuration for more info
  - name: release
    type: github-release
    source:
      owner: my-github-user
      repository: my-github-repo
      acces_token: github-access-token
      # other settings...

jobs:
  - name: prepare-release
    plan:
      - put: metadata
      - get: release

      - task: setup-release-properties
        config:
          platform: linux
          image_resource:
            type: docker-image
            source:
              repository: busybox

          inputs:
            - name: metadata

          # A URL to the build and other release properties
          # will be available as files in the properties folder
          outputs:
            - name: properties

          run:
            path: sh
            args:
              - -exc
              - |
                # Grab the metadata
                url=$(cat metadata/atc_external_url)
                team=$(cat metadata/build_team_name)
                pipeline=$(cat metadata/build_pipeline_name)
                job=$(cat metadata/build_job_name)
                build=$(cat metadata/build_name)

                # Generate the build URL to a file
                echo $url/teams/$team/pipelines/$pipeline/jobs/$job/builds/$build > properties/body

                # Write the release name to a file
                echo v1.0.0 > properties/name

                # The tag must already exist in git
                echo 1.0.0 > properties/tag

      # The put step creates a new GitHub release at the specified tag and
      # its body will contain a link to the current build
      - put: release
        params:
          name: properties/name
          tag: properties/tag
          body: properties/body
```
