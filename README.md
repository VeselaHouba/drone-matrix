# drone-matrix
Dynamic drone config for molecule testing


## Testing config

```bash
docker build -t drone -f Dockerfile.drone .
docker run --rm -ti -e DRONE_SERVER -e DRONE_TOKEN -v $(pwd):/opt/drone-matrix -w /opt/drone-matrix drone starlark convert --stdout
```
