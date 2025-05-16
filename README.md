This is a proof-of-concept project that builds an s3 middleware plugin for Munki 7.

It is a port of Wade Robson's s3 auth middleware:
https://github.com/waderobson/s3-auth

Though some unit testing was done to confirm that given the same inputs, the Swift implementation generates the same outputs as the Python implementation, as of May 15, 2025, this has not actually been tested against a repo hosted on s3. If you test it and it works, please let me know!

The middleware plugin must be installed in /usr/local/munki/middleware/, and you need Munki 7.0.0.5139 or later to test.

To build the middleware plugin and an Installer pkg that installs it, cd into this directory and run `./build_pkg.sh`. You will need a recent version of Xcode.