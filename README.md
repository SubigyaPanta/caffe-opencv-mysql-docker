# caffe-opencv-mysql-docker

## Basic usage
`docker run --rm --runtime=nvidia -v /path/to/Analytics:/workspace -it subigya/caffe-opencv:0.93 /bin/bash`

### To check what is installed and what is not
#### install ccmake
```
sudo apt-get install cmake-curses-gui
// goto build directory
ccmake ..
```

