## About
Middleware maintained by @aysiu & @aanklewicz

This is a project that builds an s3 middleware plugin for Munki 7.

It is a Swift port of Wade Robson's Python s3 auth middleware (which was compatible with Munki versions 6 and earlier):
https://github.com/waderobson/s3-auth

## Minimum Requirements
- This plugin requires Munki 7.0.0.5152 or later.
- You should already have an [AWS S3 bucket](https://aws.amazon.com/s3/) set up with [read-only credentials](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonS3ReadOnlyAccess.html).
- Your Munki repo should be uploaded to the S3 bucket.

More details on [setting up the S3 bucket](https://github.com/waderobson/s3-auth/wiki/S3-Buckets) and [creating relevant user accounts](https://github.com/waderobson/s3-auth/wiki/Creating-Read-only-Users) are in [the wiki for the Python middleware](https://github.com/waderobson/s3-auth/wiki).

## Configuring the Munki client
### Setting the preferences
To set preferences on your client Macs, you can use `defaults write` commands (substitute your actual `AccessKey`, `SecretKey`, and `Region` values in place of the ones below, which are just examples):
```
sudo defaults write /Library/Preferences/ManagedInstalls AccessKey 'AKIAIX2QPWZ7EXAMPLE'
sudo defaults write /Library/Preferences/ManagedInstalls SecretKey 'z5MFJCcEyYBmh2BxbrlZBWNJ4izEXAMPLE'
sudo defaults write /Library/Preferences/ManagedInstalls Region 'us-west-2'
```
You can also, of course, use your MDM to set a configuration profile that uses the `ManagedInstalls` preference domain and then sets the `AccessKey`, `SecretKey`, and `Region`.

### Installing the middleware
You may download an Installer package for the current release of the middleware plugin from the [Releases](https://github.com/munki/S3Middleware/releases) section.

To build the middleware plugin and an Installer pkg that installs it, `git clone` this project, `cd` into the project directory, and run `./build_pkg.sh`. You will need a recent version of Xcode.
