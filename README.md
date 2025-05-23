This is a proof-of-concept project that builds an s3 middleware plugin for Munki 7.

It is a port of Wade Robson's s3 auth middleware:
https://github.com/waderobson/s3-auth

Some unit testing is in place to confirm that given the same inputs, the Swift implementation generates the same outputs as the Python implementation. Some very cursory testing against a Munki repo on S3 has been successful (thanks @aysiu).

The middleware plugin must be installed in /usr/local/munki/middleware/, and you need Munki 7.0.0.5139 or later to test.

To build the middleware plugin and an Installer pkg that installs it, cd into this directory and run `./build_pkg.sh`. You will need a recent version of Xcode.