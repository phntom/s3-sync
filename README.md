# s3-sync kubernetes sidecar

Quickly backup and restore your container's data volume by uploading it to S3.

Cheap out on persistent volumes for stuff like alertsmanager or even prometheus.

### Configuration TL;DR


Environment variable name | Description | Example
--- | --- | ---
`S3_URL` | An s3 path to store the data | `s3://bucket/prefix/`
`S3_DIRECTORY` | Local path mounted with data | `/postgresql/`
`S3_ENDPOINT_HOSTNAME` | Hostname of an alternative s3 endpoint | `eu-central-1.linodeobjects.com`
`SLEEP_AFTER_PUSH` | Number of seconds to sleep after a full upload session | `"300"`
`USERID` | User ID files should be written with, must come with `GROUPID` and cannot be zero for both | `"1001"`
`GROUPID` | Group ID files should be written with, must come with `USERID` and cannot be zero for both | `"1001"`
`AWS_ACCESS_KEY_ID` | Standard AWS access key | `xxxxxxxxxx`
`AWS_SECRET_ACCESS_KEY` | Standard AWS key secret | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`


### What do I need to do

Pass an S3 path to S3_URL and provide credentials like an AWS_ACCESS_KEY_ID 
AWS_SECRET_ACCESS_KEY pair, but any other AWS compliant credentials will
also work fine. Custom endpoints (minio/backblaze/linode/digitalocean/etc)
can be passed through S3_ENDPOINT_HOSTNAME

Figure out the name of the volume your pod uses for data, try:
`kubectl describe pod name` section

Add a sidecar (sometimes called container) to your pod to back up your data.

Add an initContainer to your pod to restore the data on startup.

Examples for alertmanager, prometheus, postgresql, homeassistant will be
provided below. This should cover most of the prominent helm styles.

