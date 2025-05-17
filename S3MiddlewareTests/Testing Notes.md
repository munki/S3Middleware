Here is a hacked-up version of the orginal Python implementation (hacked to use static dates and inputs, and print out various bits it calculates):

```python
import base64
import datetime
import hashlib
import hmac
# backwards compatibility for python2
try:
    from urlparse import urlparse
except ImportError:
    from urllib.parse import urlparse

# pylint: disable=E0611
from Foundation import CFPreferencesCopyAppValue
# pylint: enable=E0611

BUNDLE_ID = 'ManagedInstalls'
__version__ = '1.3'
METHOD = 'GET'
SERVICE = 's3'

def pref(pref_name):
    """Return a preference. See munkicommon.py for details
    """
    pref_value = CFPreferencesCopyAppValue(pref_name, BUNDLE_ID)
    return pref_value


ACCESS_KEY = "FOO" #pref('AccessKey')
SECRET_KEY = "BAR" #pref('SecretKey')
REGION = "BAZ" #pref('Region')
S3_ENDPOINT = 's3.amazonaws.com' #pref('S3Endpoint') or 's3.amazonaws.com'


def sign(key, msg):
    return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()


def get_signature_key(key, datestamp, region, service):
    kdate = sign(('AWS4' + key).encode('utf-8'), datestamp)
    kregion = sign(kdate, region)
    kservice = sign(kregion, service)
    ksigning = sign(kservice, 'aws4_request')
    return ksigning


def uri_from_url(url):
    parse = urlparse(url)
    return parse.path


def host_from_url(url):
    parse = urlparse(url)
    return parse.hostname


def s3_auth_headers(url):
    """
    Returns a dict that contains all the required header information.
    Each header is unique to the url requested.
    """
    # Create a date for headers and the credential string
    #time_now = datetime.datetime.utcnow()
    #amzdate = time_now.strftime('%Y%m%dT%H%M%SZ')
    amzdate = "20250513T150921Z"
    #datestamp = time_now.strftime('%Y%m%d')  # Date w/o time, used in credential scope
    datestamp = "20250513"
    uri = uri_from_url(url)
    host = host_from_url(url)
    canonical_uri = uri
    canonical_querystring = ''
    canonical_headers = 'host:{}\nx-amz-date:{}\n'.format(host, amzdate)
    signed_headers = 'host;x-amz-date'
    payload_hash = hashlib.sha256(''.encode('utf-8')).hexdigest()
    canonical_request = '{}\n{}\n{}\n{}\n{}\n{}'.format(METHOD,
                                                        canonical_uri,
                                                        canonical_querystring,
                                                        canonical_headers,
                                                        signed_headers,
                                                        payload_hash)
    algorithm = 'AWS4-HMAC-SHA256'
    credential_scope = '{}/{}/{}/aws4_request'.format(datestamp, REGION, SERVICE)
    hashed_request = hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()
    print("****hashed_request****")
    print(hashed_request)
    print("**********************")
    string_to_sign = '{}\n{}\n{}\n{}'.format(algorithm,
                                             amzdate,
                                             credential_scope,
                                             hashed_request)
                                             
    print("****string to sign****")
    print(string_to_sign)
    print("**********************")
    signing_key = get_signature_key(SECRET_KEY, datestamp, REGION, SERVICE)
    print("****signing key****")
    print(base64.b64encode(signing_key))
    print("*******************")
    signature = hmac.new(signing_key, (string_to_sign).encode('utf-8'), hashlib.sha256).hexdigest()
    print("****signature****")
    print(signature)
    print("*****************")
    authorization_header = ("{} Credential={}/{},"
                            " SignedHeaders={}, Signature={}").format(algorithm,
                                                                      ACCESS_KEY,
                                                                      credential_scope,
                                                                      signed_headers,
                                                                      signature)

    headers = {'x-amz-date': amzdate,
               'x-amz-content-sha256': payload_hash,
               'Authorization': authorization_header}
    return headers

print("Output for sign:")
print(base64.b64encode(sign("FOO".encode("utf-8"), "BAR")))
print()

print(s3_auth_headers("https://example.com"))
```

Running this script provides output we then use for our expected values in the tests of the Swift version. Here's that output:

```
Output for sign:
b'fk+tOTds7rkT7JbQxHyqlAw5745HM/T6PNUe4/V9WVU='

****hashed_request****
483d56658251ef4f6adb7a8d16d9967985a798e421da7cfc4f943cb1a8b33fc2
**********************
****string to sign****
AWS4-HMAC-SHA256
20250513T150921Z
20250513/BAZ/s3/aws4_request
483d56658251ef4f6adb7a8d16d9967985a798e421da7cfc4f943cb1a8b33fc2
**********************
****signing key****
b'pidbX12YR7des1kzcj/FgFejlS15yW+OGrR9NPNR2R4='
*******************
****signature****
e61c7ab72b15ddd42c9b5b632228ae871cbdc32e490ca661b98c27c8fd6078fb
*****************
{'x-amz-date': '20250513T150921Z', 'x-amz-content-sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'Authorization': 'AWS4-HMAC-SHA256 Credential=FOO/20250513/BAZ/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=e61c7ab72b15ddd42c9b5b632228ae871cbdc32e490ca661b98c27c8fd6078fb'}
```