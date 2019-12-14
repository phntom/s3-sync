# Redis-S3

A simple Redis image backed by S3 storage.

## Background
Sometimes you'd like to use a Redis store and you'd like to save it's data, but you don't want to
waste an entire Kubernetes PersistentVolume on it, because that might waste most of a gigabyte or ten
for a few kilobytes of storage. Enter koehn/redis-s3. 

This image will take the files Redis outputs to the (default) `/data` directory and sync them to 
S3 using the Redis and s3cmd configuration you supply. The next time the container is started, the contents
will sync back to the `/data` directory prior to Redis starting up. 

## Configuration
You should run `s3cmd --configure` to set up how s3cmd will talk to your S3 bucket. You should then
map the resulting `.s3cfg` file into your container at `/root/.s3cfg`. 

You **must** supply an environment variable S3_URL with the bucket/prefix where you want your data
stored, e.g., `s3://foo-redis/`. The bucket must exist already. 

You may configure how often Redis clushes its cache to disk, whether it uses append-only mode (AOF)
or a regular RDB dump file, or it will use the Redis defaults. Create a `redis.conf` file with your
configuration and map it into your container as needed. 

You may also configure a GPG key to use (and configure s3cmd to use it) and your data will be
encypted/decrypted to/from S3. 
