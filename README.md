Middleware maintained by @aysiu & @aanklewicz

This is a project that builds an s3 middleware plugin for Munki 7.

It is a port of Wade Robson's s3 auth middleware:
https://github.com/waderobson/s3-auth

Some unit testing is in place to confirm that given the same inputs, the Swift implementation generates the same outputs as the Python implementation. Some very cursory testing against a Munki repo on S3 has been successful (thanks @aysiu).

This plugin requires Munki 7.0.0.5152 or later.

Configuration is the same as the Python plugin, detailed [here](https://github.com/waderobson/s3-auth/wiki#step-2).

You may download an Installer package for the current release of the middleware plugin from the [Releases](https://github.com/munki/S3Middleware/releases) section.

To build the middleware plugin and an Installer pkg that installs it, `git clone` this project, `cd` into the project directory, and run `./build_pkg.sh`. You will need a recent version of Xcode.
