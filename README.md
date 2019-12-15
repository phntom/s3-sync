# S3-Sync
A simple helper image for syncing volumes with S3 for quasi-reliable 
storage. Uses [S3Cmd](https://s3tools.org/s3cmd) for syncing. 

## Background
Sometimes you’d like to use a Redis store and you’d like to save its data, but 
you don’t want to waste an entire Kubernetes PersistentVolume on it, because 
that might waste most of a gigabyte or ten for a few kilobytes of storage. 
Enter koehn/s3-sync.

This image can watch a directory on a volume you specify and sync it to a bucket 
on an S3-compatible server. It’s not perfect backups, but it’s good enough for 
cached data that you’d rather not build every time your container launches. 

This approach puts the syncing into two containers: an initContainer which pulls
the contents of the S3 bucket into the volume before the main container starts, 
and a sidecar container which monitors changes in the volume and pushes them up 
to the server.

Because the push sync is in a separate container, it’s non-blocking, so your
main container will continue to run even in the event of slow internet or a loss
of connectivity to the S3 service. Additionally, no changes need to be made to
your main container’s image: it doesn’t need to be aware that it’s being synced
at all. The downside is that there’s no guarantee that changes to the volume
*will* be synced to the S3 server, so keep that in mind. 

## Configuration
You must run `s3cmd --configure` to set up how s3cmd will talk to your S3 
bucket. You should then map the resulting `.s3cfg` file into your container at 
`/.s3cfg`. 

You must supply an environment variable S3_URL with the bucket/prefix where you 
want your data stored, e.g., `s3://foo-redis/`. The bucket must exist already. 
You must supply a `S3_DIRECTORY` environment variable containing a path to the 
directory to sync. **Both the `S3_URL` and the `S3_DIRECTORY` variables must 
end in a slash (`/`).**

You should configure environment variables USERID and GROUPID, which will be set
prior to running s3cmd to insure that files have the appropriate user:group 
metadata set. 

In a Kubernetes environment, you should configure two s3-sync containers: an 
initContainer with a `command: ["startup"]`, and a regular container, with no 
command. It’s wise to add a `preStop` command to flush any changes from the
server to disk, helping the s3-sync container have a chance to push them to S3.

## Debugging
The containers both log to stdout, and the scripts they run are very simple, so
it should be easy enough to figure out what's wrong. If all else fails, drop in
and run the `startup`, `push`, and `watch` commands and see what's happening. It
should be easy to run the container locally for testing. 

The main source repo for this image is on my 
[GitLab site](https://gitlab.koehn.com/docker/s3-sync).

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
