# easyCT

Camera trapping anlaysis easier than ever before thanks to Machine Learning classification. 

## Description

This is a web application intended to run locally on your computer. It allows you to load your photos
from a camera trap survey and analyze them using a Machine Learning classifier. You can also get some insight
into the distribution of your photos over time.

## Getting Started

### Dependencies

* You need to have Docker on your machine. The easiest way to use it is to download
[Docker Desktop](https://www.docker.com/products/docker-desktop).
* **Warning**: Due to the new architecture of Apple computers (i.e. Apple Silicon M1 line),
they are currently not supported

### Installing

* Pull the official image from the Docker Hub:
```{bash}
docker pull dzionek/easy-ct:latest
```

### Executing program

* Run the image. Substitute [PUT YOUR PATH HERE] with the path containing your photo directories.

```
docker run -d --rm -p 3838:3838 -v [PUT YOUR PATH HERE]:/root/photos dzionek/easy-ct
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
