--[[
HAPPy Intervalometer and logging script by Greg Lawler

CHDK High altitude balloon intervalometer and logging script.
HAPPy (High Altitude Photo Project, Yay!) is the name we gave to our first balloon launch.
This script was written specifically for taking photos from a balloon payload using a Canon
point and shoot camera running CHDK. By far the easiest way to get started with CHDK is
to use the STICK tool from http://www.zenoshrdlu.com/stick/stick.html
Intervalometer functions based on a script by Fraser McCrossan

This script will configure your Canon camera to auto-focus, take a photo
every x seconds and will record the time, temperature of the lens, CCD and battery 
to a CSV log file.
The script can be run in Endless mode until the battery life or storage space runs out.

HAPPy project - High Altitude Photo Project - http://happycapsule.com.
A high altitude balloon project which aims to photograph the earth from near space.

Features:
 - HAPPy logging - write temperature (C), battery voltage (mV) and timestamp data to log file.
 - Log files located in CHDK/LOGS/
 - Endless mode - will keep taking photos until battery dies or card is full.
 - Turns off the display to extend battery life.
 - Auto focus and expose for each photo.

See the README file for instructions and GPL license info.


--]]

--[[
-- Options that can be changed in camera when the script starts.
@title HAPPy Intervalometer
@param s Interval seconds 
@default s 20
@param h Sequence hours
@default h 0
@param m Sequence minutes
@default m 5
@param e Endless? 0=No 1=Yes
@default e 1
@param f Focus: 0=Every 1=Start
@default f 0
@param d Display off frame 0=Never
@default d 3
@param l Enable HAPPy log 1=Yes
@default l 1
--]]


-- convert parameters into readable variable names
secs_frame, hours, minutes, endless, focus_at_start, display_off_frame = s, h, m, (e > 0), (f > 0), d

-- propcase to convert words to proper case.
props = require "propcase"

-- derive actual running parameters from the more human-friendly input parameters
function calculate_parameters (seconds_per_frame, hours, minutes, start_ticks)
   local ticks_per_frame = 1000 * secs_frame -- ticks per frame
   local total_frames = (hours * 3600 + minutes * 60) / secs_frame -- total frames
   local end_ticks = start_ticks + total_frames * ticks_per_frame -- ticks at end of sequence
   return ticks_per_frame, total_frames, end_ticks
end

function HAPPy_time()
   yy = (get_time("Y"))
   hh = (get_time("h"))
   if (tonumber(hh)<10) then
      hh = "0"..hh
   end
   mi = (get_time("m"))
   if (tonumber(mi)<10) then
      mi = "0"..mi
   end
   ss = (get_time("s"))
   if (tonumber(ss)<10) then
      ss = "0"..ss
   end
   mm   = (get_time("M"))
   if (tonumber(mm)<10) then
      mm = "0"..mm
   end
   dd   = (get_time("D"))
   if (tonumber(dd)<10) then
      dd = "0"..dd
   end
   hhmmss = hh .. ":" .. mi .. ":" .. ss
   MMYYYY = yy .. "-" .. dd .. "-" .. mm
end

--  CSV header columns
--  Photo Number,Date,Time,Battery Voltage,Lens Temp,CCD Temp,Battery Temp,Elapsed Time

function print_status (frame, total_frames, ticks_per_frame, end_ticks, endless)
  local free = get_jpg_count()
  HAPPy_time()
  print_screen( frame )
  output_line1 = frame .. "," .. MMYYYY .. "," .. hhmmss .. "," .. get_vbatt() .. "," .. get_temperature(0) .. "," .. get_temperature(1) .. "," .. get_temperature(2)
   if endless then
      local h, m, s = ticks_to_hms(frame * ticks_per_frame)
      elapsed_time = h .. ":" .. m .. ":" .. s
      csv_out = output_line1 .. "," .. elapsed_time
      print( csv_out )
   else
      local h, m, s = ticks_to_hms(end_ticks - get_tick_count())
      print(frame .. "/" .. total_frames .. ", " .. h .. "h" .. m .. "m" .. s .. "s/" .. free .. " left")
   end
end

function ticks_to_hms (ticks)
   local secs = (ticks + 500) / 1000 -- round to nearest second
   local s = secs % 60
   secs = secs / 60
   local m = secs % 60
   local h = secs / 60
   return h, m, s
end

-- sleep, but using wait_click(); return true if a key was pressed, else false
function next_frame_sleep (frame, start_ticks, ticks_per_frame)
   -- this calculates the number of ticks between now and the time of
   -- the next frame
   local sleep_time = (start_ticks + frame * ticks_per_frame) - get_tick_count()
   if sleep_time < 1 then
      sleep_time = 1
   end
   wait_click(sleep_time)
   return not is_key("no_key")
end

-- delay for the appropriate amount of time, but respond to
-- the display key (allows turning off display to save power)
-- return true if we should exit, else false
function frame_delay (frame, start_ticks, ticks_per_frame)
   -- this returns true while a key has been pressed, and false if
   -- none
   while next_frame_sleep (frame, start_ticks, ticks_per_frame) do
      -- honour the display button
      if is_key("display") then
         click("display")
      end
      -- if set key is pressed, indicate that we should stop
      if is_key("set") then
         return true
      end
   end
   return false
end

-- if the display mode is not the passed mode, click display and return true
-- otherwise return false
function seek_display_mode(mode)
   if get_prop(props.DISPLAY_MODE) == mode then
      return false
   else
      click "display"
      return true
   end
end

-- switch to autofocus mode, pre-focus, then go to manual focus mode
function pre_focus()
   local focused = false
   local try = 1
   while not focused and try <= 5 do
      print("Pre-focus attempt " .. try)
      press("shoot_half")
      sleep(2000)
      if get_prop(67) > 0 then
         focused = true
         set_aflock(1)
      end
      release("shoot_half")
      sleep(500)
      try = try + 1
   end
   return focused
end

if focus_at_start then
   if not pre_focus() then
      print "Unable to reach pre-focus"
   end
end

start_ticks = get_tick_count()

ticks_per_frame, total_frames, end_ticks = calculate_parameters(secs_frame, hours, minutes, start_ticks)

frame = 1
original_display_mode = get_prop(props.DISPLAY_MODE)

print "Press SET to exit"
-- set_backlight(0) 
-- target_display_mode = 2 -- off
set_lcd_display(0)
while endless or frame <= total_frames do
   print_status(frame, total_frames, ticks_per_frame, end_ticks, endless)
   if display_off_frame > 0 and frame >= display_off_frame then
      seek_display_mode(target_display_mode)
   end
   shoot()
   if frame_delay(frame, start_ticks, ticks_per_frame) then
      print "User quit"
      break
   end
   frame = frame + 1
end

-- restore display mode
if display_off_frame > 0 then
   while seek_display_mode(original_display_mode) do
      sleep(1000)
   end
end

-- restore focus mode
set_aflock(0)
