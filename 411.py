#!/usr/bin/env python3
from typing import Tuple
from moviepy import editor
import os
import random
import fnmatch 
from collections import defaultdict
from pathlib import Path

from util import path_codes

videos = Path('/Users/josh/kaleido-video/').expanduser()

code_to_videos = defaultdict(list)
for video in videos.glob('*.mp4'):
    for code in path_codes(video, include_secret=False):
        code_to_videos[code].append(video)

# Only take unique codes
video_codes: Tuple[str, Path] = [
     (code, videos[0]) for code, videos in code_to_videos.items()
     if len(videos) == 1 and len(code) > 1 
]


def create_video(xdim, ydim, length, clips):
    outputs = []
    codes = []
    for code, path in random.sample(video_codes, k=clips):
        clip = editor.VideoFileClip(str(path)).resize( (xdim, ydim) ) 

        # select a random time point
        start = round(random.uniform(0,clip.duration-length), 2) 

        print('%s from %d:%02d of %s' % (code, start // 60, start % 60, path.stem))

        # cut a subclip
        out_clip = clip.subclip(start,start+length)
            
        txt_clip = editor.TextClip(code, fontsize = 180, color = 'white') 

        bg_clip = editor.TextClip(code, fontsize = 180, color = 'black')  
        width, height = txt_clip.size 
        x, y = (xdim // 2 - width // 2, ydim // 2 - height // 2)
        txt_clip = txt_clip.set_pos((x-5, y-5)).set_duration(length)  
        bg_clip = bg_clip.set_pos((x + 5, y+5)).set_duration(length)  

        codes.append(code)
        outputs.append(editor.CompositeVideoClip([out_clip, bg_clip, txt_clip]))

    # combine clips from different videos
    collage = editor.concatenate_videoclips(outputs) 

    collage.write_videofile('411__%s.mp4' % '-'.join(codes), audio_codec="aac")


create_video(xdim=2752, ydim=2064, length=4, clips=15)
