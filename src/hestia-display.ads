-----------------------------------------------------------------------
--  hestia-display -- Display manager
--  Copyright (C) 2016, 2017 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with HAL.Bitmap;
with HAL.Touch_Panel;
with Ada.Real_Time;
with Net;

with UI.Buttons;
with UI.Graphs;
with UI.Displays;
package Hestia.Display is

   --  Color to draw a separation line.
   Line_Color : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Blue;
   Hot_Color  : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Red;
   Cold_Color : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Blue;
   Line_Sep_Color : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Royal_Blue;

private

   B_MAIN  : constant UI.Buttons.Button_Index := 1;
   B_SETUP : constant UI.Buttons.Button_Index := 2;
   B_STAT  : constant UI.Buttons.Button_Index := 3;

   function Format_Packets (Value : in Net.Uint32) return String;
   function Format_Bytes (Value : in Net.Uint64) return String;
   function Format_Bandwidth (Value : in Net.Uint32) return String;

   --  Initialize the display.
   procedure Initialize;

   --  Draw the layout presentation frame.
   procedure Draw_Frame (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class);

   --  Display the current heat schedule and status.
   procedure Display_Main (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class);

   --  Display the schedule setup.
   procedure Display_Setup (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class);

   procedure Display_Time (Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                           Deadline : out Ada.Real_Time.Time);

   --  Display a performance summary indicator.
   procedure Display_Summary (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class);

end Hestia.Display;
