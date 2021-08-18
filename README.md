# easyCT

Camera trapping anlaysis easier than ever before thanks to machine learning classification. 

## Description

This is an application intended to run locally on your computer in a web browser of your choice. It allows you to load your photos
from a camera trap survey and analyze them using a machine learning classifier. You can also get some insight
into the distribution of your photos over time.

The app was created in [R Shiny](https://shiny.rstudio.com). It uses many R and Python libraries. [Exiftool](https://exiftool.org) is used for
extracting metadata from photos. The machine learning part 
is based on [Tensorflow](https://www.tensorflow.org).

## Getting Started

### Prerequisites

* You need to have [Docker](https://www.docker.com) installed on your machine. The easiest way to use it is to download
[Docker Desktop](https://www.docker.com/products/docker-desktop).
* You must have a modern web browser to see the application (Chrome, Opera, Safari, Firefox, etc).
* **Warning**: Due to the new architecture of Apple computers (i.e. Apple Silicon M1 onwards),
they are currently not supported.

### Installing
Installation and execution is done inside a command-line interface existing inside your operating system.
If you use Windows, open CMD; on MacOS and Linux open Terminal. Then, copy-paste the commands below.

**Important:** Make sure Docker is running in the background before executing the commands below.
If you have installed Docker Desktop, you need to open this application beforehand (otherwise you will
see a warning saying `the docker daemon is not running`).

* First command: Pull the official image from [Docker Hub](https://hub.docker.com/repository/docker/dzionek/easy-ct):
```{bash}
docker pull dzionek/easy-ct:latest
```

This may take a while as you need to download 5 GB. In the meantime, you can enjoy a cup of tea or coffee.
Make sure you have enough space on your drive and you don't close the command-line interface during this process.

### Executing program

* Second command: Run the image. You need to modify the part with square brackets.
Substitute `[PUT YOUR PATH HERE]` with the path containing your photo directories.

```{bash}
docker run -d --rm -p 3838:3838 -v [PUT YOUR PATH HERE]:/root/photos dzionek/easy-ct
```

The application will be available after a few minutes at [http://localhost:3838/](http://localhost:3838/).

### Example installing and running.
Suppose I use Windows and have my camera trap photos stored at an external hard drive in a folder
`H:\camera_traps\site01`. Then, all I need to do (for installing and running) is paste:

```{bash}
docker pull dzionek/easy-ct:latest
docker run -d --rm -p 3838:3838 -v H:\camera_traps\site01:/root/photos dzionek/easy-ct
```

After that, I wait 1-2 minutes so that my application is ready. Then, I open my favourite web browser
(say Firefox) and go the link [http://localhost:3838/](http://localhost:3838/). The photos stored at
`H:\camera_traps\site01` will be available inside `Home/photos` directory within the web application.

## Author
The project was created by Bartosz Dzionek during his Research Experience Placement 2021 at the [Zoological Society of London](https://www.zsl.org)
and [Imperial College London](https://www.imperial.ac.uk/grantham/). Many thanks to [Dr. Marcus Rowcliffe](https://www.zsl.org/science/users/marcus-rowcliffe),
[Verity Miles](https://www.imperial.ac.uk/people/v.miles20), and others for supervision and great advice.

The application is based on a binary classifier developed by the ZSL and available at [https://github.com/Zoological-Society-of-London/camtrap_classifier](https://github.com/Zoological-Society-of-London/camtrap_classifier).

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the [MIT License](https://choosealicense.com/licenses/mit/) - see the LICENSE file for details.
