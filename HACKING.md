# Hacking

## Testing

The project includes a simple test application that can be run with `docker-compose up`.
The app runs on port 8080 and `/` returns a plaintext response of "Hello World!"
If the path is an integer (e.g. `/1`) it will wait that many seconds before returning.

## Releasing

To create a new release, run the following commands with both the latest version and the `latest` tag.

```
docker buildx build --platform linux/amd64,linux/arm64 --tag luhn/spillway:1.0 --push .
```

To push to AWS ECR:

```
aws ecr-public get-login-password --region us-east-1 --profile personal | docker login --username AWS --password-stdin public.ecr.aws/luhn
docker buildx build --platform linux/amd64,linux/arm64 --tag public.ecr.aws/luhn/spillway:1.0 --push .
```
