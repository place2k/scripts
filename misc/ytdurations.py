#!/usr/bin/python

from os import getenv
from re import compile as Regex # classnamelike alias
from requests import get as GET


class Duration:
  def __init__(self, s):
    self.H, self.M, self.S = [0, 0, 0] # no D (days) field because none of the videos I bookmarked is longer than 24h
    digit = ''
    for c in s[2:]:
      if c.isdigit():
        digit += c
      else:
        self.__dict__[c] = int(digit)
        digit = ''

class TotalDuration:
  def __init__(self, durations):
    self.H = sum([d.H for d in durations])
    self.M = sum([d.M for d in durations])
    self.S = sum([d.S for d in durations])
    self.H += M // 60
    self.M  %= 60
    self.M //= 60
    self.

  def __repr__(self):
    return f'{str(self.H) + ':' if H else ''}{self.M:02d}:{self.S%60:02d}'

class DurationList:
  def __init__(self):
    self.durations = []

  def add(self, d):
    self.durations.append(d)

  def sum(self):

class Video:
  def __init__(self, id):
    self.id = self.duration = None

    res = GET(f'https://www.googleapis.com/youtube/v3/videos?key={APIKEY}&part=contentDetails&fields=items/contentDetails/duration&id={id}').json()
    if 'error' in res:
      E = res['error']
      print(f'Error {E['code']} ({E['status']}): {E['message']}')
    else:
      items = res['items']
      if len(items) == 0:
        print(f'No such video: {id}')
      else:
        self.id = id
        self.duration = Duration(items[0]['contentDetails']['duration'])
        return self

    return None

class VideoList:
  def __init__(self):
    self.IDs = {}
    group_header = Regex(r'YT\d{1,2}(Old)?')

    with open(getenv('HOME') + 'youtube-brave-groups.bookmarks', 'r') as ids_file:
      lines = [line.rstrip() for line in ids_file.readlines() if line != '\n']
      for line in lines:
        if group_header.match(line):
          self.IDs[line] = []
          tabgroup = line
        else:
          vid = Video(line)
          if vid: self.IDs[tabgroup].append(vid)

  def total_duration(self, tabgroup):
    pass




APIKEY = getenv('APIKEY')
if APIKEY is None: APIKEY = input('Enter YouTube API key: ')

totals = []

for tabgroup in VideoIDs.keys():
  if tabgroup == 'YT6': break # test only YT4 and YT5 for now
  dlist = []
  for VideoID in VideoIDs[tabgroup]:
    dstr = get_video_duration(VideoID)
    if dstr: dlist.append(dstr)
  dtotal = sum_durations(dlist)
  print()