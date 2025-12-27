This is a proof-of-concept project that builds an s3 middleware plugin for Munki 7.

It is a port of Wade Robson's s3 auth middleware:
https://github.com/waderobson/s3-auth

Some unit testing is in place to confirm that given the same inputs, the Swift implementation generates the same outputs as the Python implementation. Some very cursory testing against a Munki repo on S3 has been successful (thanks @aysiu).

The middleware plugin must be installed in `/usr/local/munki/middleware/`, and you need Munki 7.0 or later to to use thhis plugin.

Configuration is the same as the Python plugin, detailed [here](https://github.com/waderobson/s3-auth/wiki#step-2).

You may download the current release of the middleware plugin from the [Releases](https://github.com/munki/S3Middleware/releases) section.

To build the middleware plugin and an Installer pkg that installs it, cd into this directory and run `./build_pkg.sh`. You will need a recent version of Xcode.
