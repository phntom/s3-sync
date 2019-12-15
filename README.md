# S3-Sync

A simple helper container for syncing volumes with S3 for quasi-reliable storage. 

## Background
Sometimes you'd like to use a Redis store and you'd like to save it's data, but you don't want to waste an entire Kubernetes PersistentVolume on it, because that might waste most of a gigabyte or ten for a few kilobytes of storage. Enter koehn/s3-sync.

This image can watch a directory on a volume you specify and sync it to a bucket on an S3-compatible server. It’s not perfect backups, but it’s good enough for cached data that you’d rather not build every time your container launches. 

## Configuration
You must run `s3cmd --configure` to set up how s3cmd will talk to your S3 bucket. You should then
map the resulting `.s3cfg` file into your container at `/.s3cfg`. 

You must supply an environment variable S3_URL with the bucket/prefix where you want your data
stored, e.g., `s3://foo-redis/`. The bucket must exist already. You must supply a `S3_DIRECTORY`
environment varible containing a path to the directory to sync. *Both the `S3_URL` and the
`S3_DIRECTORY` variables **must** end in a slash (`/`).*

You should configure environment variables USERID and GROUPID, which will be set prior to running
s3cmd to insure that files have the appropriate user:group metadata set. 

In a Kubernetes environment, you should configure two s3-sync containers: an initContainer with a 
`command: ["startup"]`, and a regular container, with no command. 

## Sample configuration
Here's a sample configuration of a Redis server running with S3 Sync configured to sync the 
Redis `/data` directory. 

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis
  name: redis
  namespace: foo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: redis
    spec:
      initContainers:
      - name: s3sync-startup
        command: ["startup"]
        image: koehn/s3-sync:2.0.2-8
        env:
        - name: USERID
          value: "999"
        - name: GROUPID
          value: "1000"
        - name: S3_URL
          value: s3://foo-redis/
        - name: S3_DIRECTORY
          value: /data/
        volumeMounts:
        - mountPath: /data
          name: redis
        - mountPath: /.s3cfg
          name: redis-s3cfg
          subPath: s3cfg
          readOnly: true
      containers:
      - args:
        - redis-server
        image: redis:5.0.7-alpine
        imagePullPolicy: Always
        name: redis
        lifecycle:
          preStop:
            exec:
              command: ["sh", "-c", "echo 'SHUTDOWN SAVE' | redis-cli"]
        volumeMounts:
        - mountPath: /data
          name: redis
      - image: koehn/s3-sync:2.0.2-8
        name: s3-sync
        env:
        - name: USERID
          value: "999"
        - name: GROUPID
          value: "1000"
        - name: S3_URL
          value: s3://foo-redis/
        - name: S3_DIRECTORY
          value: /data/
        volumeMounts:
        - mountPath: /data
          name: redis
        - mountPath: /.s3cfg
          name: redis-s3cfg
          subPath: s3cfg
          readOnly: true
      restartPolicy: Always
      volumes:
      - name: redis
        emptyDir: {}
      - name: redis-s3cfg
        configMap:
          name: redis-s3cfg
```
