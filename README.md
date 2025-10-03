# s3-sync Kubernetes Sidecar

A Kubernetes sidecar container that continuously backs up a container's data volume to an S3-compatible object storage service. It can also restore the data on startup.

This is useful for stateful applications where you might not want to use a persistent volume, for example, for Prometheus or Alertmanager.

This image uses `s3cmd` version 2.4.0.

### Configuration

The container is configured using environment variables.

| Environment Variable      | Description                                                                                                                              | Example                          |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `S3_URL`                  | **Required.** The S3 path to store the data.                                                                                             | `s3://my-bucket/my-prefix/`      |
| `S3_DIRECTORY`            | **Required.** The local path that is mounted as a volume.                                                                                | `/data/`                         |
| `S3_ENDPOINT_HOSTNAME`    | The hostname of an S3-compatible endpoint (e.g., MinIO, Linode Objects, etc.).                                                           | `eu-central-1.linodeobjects.com` |
| `SLEEP_AFTER_PUSH`        | The number of seconds to sleep after a successful upload. Can be used to rate-limit pushes.                                              | `300`                            |
| `USERID`                  | The user ID that the files should be owned by. If set, `s3cmd` will be run as this user.                                                  | `1001`                           |
| `GROUPID`                 | The group ID that the files should be owned by. If `USERID` is set and `GROUPID` is not, it defaults to `1111`.                            | `1001`                           |
| `EMPTY_S3_PATHS`          | If set to any value, the container will track and restore empty directories.                                                             | `true`                           |
| `AWS_ACCESS_KEY_ID`       | Your AWS access key ID.                                                                                                                  | `xxxxxxxxxx`                     |
| `AWS_SECRET_ACCESS_KEY`   | Your AWS secret access key.                                                                                                              | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `AWS_ROLE_ARN`            | The ARN of an IAM role to assume.                                                                                                        | `arn:aws:iam::123456789012:role/MyRole` |
| `AWS_WEB_IDENTITY_TOKEN_FILE` | The path to a file containing a web identity token. Used for IAM Roles for Service Accounts (IRSA).                                       | `/var/run/secrets/eks.amazonaws.com/serviceaccount/token` |

**Note:** Any standard AWS credential-related environment variables will also work (e.g., `AWS_SESSION_TOKEN`).

### How to Use

1.  **Provide S3 Credentials:** Pass an `S3_URL` and provide credentials. This can be an `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` pair, or you can use IAM roles for service accounts. For S3-compatible services (MinIO, Backblaze, Linode, etc.), set the `S3_ENDPOINT_HOSTNAME`.

2.  **Add an `initContainer`:** Add an `initContainer` to your Pod definition to restore the data from S3 on startup. This container will run the `startup` script.

3.  **Add a Sidecar:** Add a sidecar container to your Pod to continuously back up the data. This container will run the `watch` script.

You'll need to mount the same volume to your main application container, the `initContainer`, and the sidecar container.