
# Custom FFMPEG

1. Added a new avformat type 'rawvideo_with_header' to be able to output raw decoded
   video with its associated header info to a file or fifo. 

2. The header information as the following packed structure

```
struct rawdata_header {
    unsigned int      delimiter; //0xC0FFEEEE
    int               hdr_len;
    int64_t           pts;
    int64_t           len; //Raw frame size
};
```
3. Extension to be used for such a file 'hraw'.

4. Python code snippet for parsing header

```python
# Assuming buffer is byte array containin a frame with header.
(delimiter,) = struct.unpack('I', buffer[0:4])
buffer = buffer[4:]
(hdr_len,) = struct.unpack('i', buffer[0:4])
(pts, len) = struct.unpack('qq', buffer[4:20])

```


## Example usage

The command below decodes an 'input_media.mp4' file and directs the rawvideo
output prefixed by the above header for every frame. Please note the following
command line is also doing frame rate conversion to give output at 10fps.

```
ffmpeg -y -i input_media.mp4 -r 10 -vf scale=640:360 -pix_fmt rgb24 -f rawvideo_with_header out_file.hraw
```

## BUILD

```
./build_configure.shbuild_configure.sh
make all -j 4
```
