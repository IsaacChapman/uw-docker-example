# Example of using Docker with Solano CI Universal Workers

This repo demonstrates using [Docker](https://www.docker.com/) containers in
a [Solano CI](https://www.solanolabs.com/) 
[Universal Worker](http://docs.solanolabs.com/Beta/universal-worker/) build.

##### Notes on `solano.yml`:

  * The `system: docker: true` lines enable Docker for the build. It 
must also be enabled for your Solano CI organization. Please contact
support@solanolabs.com if needed.
  * The `script:` value in a
[build profile](http://docs.solanolabs.com/Beta/build-profiles/)
instructs the Universal Worker which file should be executed for the test.
  * The `environment:` section is used to specify environment variables
that will be used when executing tests.

##### Notes on `host-script.sh`:

  * Since Universal Workers do not include our standard worker's library
of services, daemons, languages, etc., they need to be installed on either
the Universal Worker or in the build. This example includes installing
`mysql-client` in the build.
  * Daemons that are needed in the build should be started in the build,
as the build environment is separate from the Universal Worker's host
environment. This example includes starting a `docker daemon` with a
specific storage driver, graph directory, and logging path.
