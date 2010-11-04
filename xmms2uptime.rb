#!/usr/bin/env ruby
#
# xmms2 ruby curses top
#
# wrotted by David Richards
#
# license is give me some money please :D 

CLIENT = "xmms2uptime"
CLIENTVERSION = "0.11 Public Alpha"


require 'curses'
include Curses
require 'time'

require "xmmsclient"

xc = Xmms::Client.new(CLIENT)
xc.connect

def get_single_line_trackinfo(trackinfohash)
  filename = trackinfohash[:url].split("/").last.to_s
  trackinfostring = trackinfohash[:artist].to_s + " - " + trackinfohash[:title].to_s
  if trackinfostring.length < 5
   return filename.ljust(60).gsub("+", " ").split(".")[0...-1].join("")
  else
   return trackinfostring.ljust(60)
  end
end


init_screen
begin
  crmode
  noecho
  stdscr.keypad(true)
  screen = stdscr.subwin(22, 70, 0, 0)
  screen.box(0,0)
  setpos(0,25); addstr("#{CLIENT} version #{CLIENTVERSION}");

  setpos(19,50); addstr("q to quit");

  Curses.timeout=0
  loop do
      case getch
      when ?Q, ?q    :  break
      else

    # update status
    status = xc.playback_status.wait.value
    if status == 1
     textstatus = "Playing"
    else
     textstatus = "Stopped"
    end

    setpos(11,6)
    addstr(textstatus)

    setpos(19,6)
    addstr( (Time.now.strftime("%m/%d/%Y %H:%M:%S")).to_s)

    infohash = xc.main_stats.wait.value.to_a
    uptime = infohash[0].last
    uptimestring = (uptime/86400).to_s + " days " + [uptime/3600 % 24, uptime/60 % 60, uptime % 60].map{|t| t.to_s.rjust(2, '0')}.join(':')

    setpos(4,6); addstr(infohash[0].first.to_s.capitalize + " " + uptimestring.to_s);
    setpos(5,6); addstr(infohash[1].first.to_s.capitalize + " " + infohash[1].last.to_s.split("(").first);
    setpos(6,6); addstr("git commit" + infohash[1].last.to_s.split(":").last.sub(")",""));

   # pluginhash = xc.plugin_list.wait.value
   # setpos(8,6); addstr(pluginhash.to_s);

    # update title

    setpos(13,6)
    addstr("Current Track:")
    playback_id = xc.playback_current_id.wait.value
 
    res = xc.medialib_get_info(playback_id).wait
    current_track = res.value.to_propdict
    trackinfostring = get_single_line_trackinfo(current_track)

    # clear old track info
    setpos(14,6)
    addstr("                                                   ")

    setpos(14,6)
    addstr(trackinfostring[0..50])


    sleep 0.8
      end
  end
ensure
  close_screen
end
