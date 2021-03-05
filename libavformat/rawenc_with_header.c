/*
 * RAW video or audio frame with some header information
 * Copyright (c) 2001 Fabrice Bellard
 * Copyright (c) 2005 Alex Beregszaszi
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "libavutil/intreadwrite.h" 

#include <stdint.h>
#include "avformat.h"
#include "rawenc.h"
#include "internal.h"

int ff_raw_write_packet_with_header(AVFormatContext *s, AVPacket *pkt);

struct rawdata_header {
    unsigned int      delimiter; //0xC0FFEEEE
    int               hdr_len;
    int64_t           pts;
    int64_t           len; //Raw frame size
};


int ff_raw_write_packet_with_header(AVFormatContext *s, AVPacket *pkt)
{
    struct rawdata_header  head = {0,};
    AVStream   *stream;
    

    head.delimiter = 0xC0FFEEEE;
    head.hdr_len = sizeof(head);
    stream = s->streams[pkt->stream_index];
    // Multiplcation by 1000 below is convert timestamp to milliseconds
    head.pts = (pkt->pts * (stream->time_base.num *1000))/stream->time_base.den;
    head.len = pkt->size;

    avio_write(s->pb, (unsigned char*)&head, sizeof(head));

    avio_write(s->pb, pkt->data, pkt->size);
    return 0;
}

#if CONFIG_RAWVIDEO_WITH_HEADER_MUXER
AVOutputFormat ff_rawvideo_with_header_muxer = {
    .name              = "rawvideo_with_header",
    .long_name         = NULL_IF_CONFIG_SMALL("raw video with header"),
    .extensions        = "hraw",
    .audio_codec       = AV_CODEC_ID_NONE,
    .video_codec       = AV_CODEC_ID_RAWVIDEO,
    .write_packet      = ff_raw_write_packet_with_header,
    .flags             = AVFMT_NOTIMESTAMPS,
};
#endif
