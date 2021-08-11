import numpy as np
from PIL import Image

def defined_crop(img, top_trim = 0, bottom_trim = 0, left_trim = 0, right_trim = 0, min_width = 50, min_height = 50):
    # Note: image_data_format is 'channel_last'
    #assert img.shape[2] == 3
    height = img.height
    width = img.width
    if ((width <= ((left_trim + right_trim) + min_width)) or (height <= ((top_trim + bottom_trim) + min_height))):
        print("Warning! Image too small to trim! Leaving image as is!")
        return(img)
    else:
        return(img.crop((left_trim, top_trim, width - right_trim, height-bottom_trim))) # Removed top 30px and bottom 100px
