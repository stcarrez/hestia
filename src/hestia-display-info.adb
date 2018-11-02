-----------------------------------------------------------------------
--  hestia-display-info -- Display information about the system
--  Copyright (C) 2018 Stephane Carrez
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
with BMP_Fonts;

with Interfaces;
with Hestia.Network;
with UI.Texts;
package body Hestia.Display.Info is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use UI.Texts;
   use type Net.Uint16;

   --  Convert the integer to a string without a leading space.
   function Image (Value : in Net.Uint32) return String;
   function Image (Value : in Net.Uint64) return String;
   function To_Digits (Val : Natural) return String;

   --  Kb, Mb, Gb units.
   KB : constant Net.Uint64 := 1024;
   MB : constant Net.Uint64 := KB * KB;
   GB : constant Net.Uint64 := MB * MB;

   --  Convert the integer to a string without a leading space.
   function Image (Value : in Net.Uint32) return String is
      Result : constant String := Net.Uint32'Image (Value);
   begin
      return Result (Result'First + 1 .. Result'Last);
   end Image;

   function Image (Value : in Net.Uint64) return String is
      Result : constant String := Net.Uint64'Image (Value);
   begin
      return Result (Result'First + 1 .. Result'Last);
   end Image;

   Dec_String : constant String := "0123456789";

   function To_Digits (Val : Natural) return String is
      Result : String (1 .. 2);
   begin
      Result (1) := Dec_String (Positive ((Val / 10) + 1));
      Result (2) := Dec_String (Positive ((Val mod 10) + 1));
      return Result;
   end To_Digits;

   function Format_Packets (Value : in Net.Uint32) return String is
   begin
      return Net.Uint32'Image (Value);
   end Format_Packets;

   function Format_Bytes (Value : in Net.Uint64) return String is
   begin
      if Value < 10 * KB then
         return Image (Net.Uint32 (Value));
      elsif Value < 10 * MB then
         return Image (Value / KB) & "." & Image (((Value mod KB) * 10) / KB) & "Kb";
      elsif Value < 10 * GB then
         return Image (Value / MB) & "." & Image (((Value mod MB) * 10) / MB) & "Mb";
      else
         return Image (Value / GB) & "." & Image (((Value mod GB) * 10) / GB) & "Gb";
      end if;
   end Format_Bytes;

   function Format_Bandwidth (Value : in Net.Uint32) return String is
   begin
      if Value < Net.Uint32 (KB) then
         return Image (Value);
      elsif Value < Net.Uint32 (MB) then
         return Image (Value / Net.Uint32 (KB)) & "."
           & Image (((Value mod Net.Uint32 (KB)) * 10) / Net.Uint32 (KB)) & "Kbs";
      else
         return Image (Value / Net.Uint32 (MB)) & "."
           & Image (((Value mod Net.Uint32 (MB)) * 10) / Net.Uint32 (MB)) & "Mbs";
      end if;
   end Format_Bandwidth;

   use Ada.Real_Time;

   ONE_MS : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (1);

   --  ------------------------------
   --  Draw the layout presentation frame.
   --  ------------------------------
   overriding
   procedure On_Restore (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is
   begin
      Display.Back_Button.Pos := (0, 0);
      Display.Back_Button.Width := 100;
      Display.Back_Button.Height := 30;
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill;
      UI.Texts.Current_Font := BMP_Fonts.Font16x24;
      UI.Texts.Draw_String (Buffer  => Buffer,
                            Start   => Display.Back_Button.Pos,
                            Width   => Display.Back_Button.Width,
                            Msg     => "Back",
                            Justify => UI.Texts.CENTER);
      Display.Prev_Time := Ada.Real_Time.Clock;
      Display.Deadline := Display.Prev_time + Ada.Real_Time.Milliseconds (1000);
   end On_Restore;

   --  Refresh the current display.
   overriding
   procedure On_Refresh (Display  : in out Display_Type;
                         Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                         Deadline : out Ada.Real_Time.Time) is
      use type Net.Uint32;
      Now       : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      Cur_Pkts  : Net.Uint32;
      Cur_Bytes : Net.Uint64;
      D         : Net.Uint32;
      C         : Net.Uint32;
   begin
      if Display.Deadline < Now then
         Cur_Bytes := Hestia.Network.Ifnet.Rx_Stats.Bytes;
         Cur_Pkts  := Hestia.Network.Ifnet.Rx_Stats.Packets;
         C := Net.Uint32 ((Now - Display.Prev_Time) / ONE_MS);
         D := Net.Uint32 (Cur_Pkts - Display.Pkts);
         Display.Speed := Net.Uint32 (D * 1000) / C;
         Display.Bandwidth := Natural (((Cur_Bytes - Display.Bytes) * 8000) / Net.Uint64 (C));
         Display.Prev_Time := Now;
         Display.Deadline := Display.Deadline + Ada.Real_Time.Seconds (1);
         Display.Pkts := Cur_Pkts;
         Display.Bytes := Cur_Bytes;
      end if;
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area  => (Position => (0, 160),
                                  Width  => 99,
                                  Height => Buffer.Height - 160));

      UI.Texts.Current_Font := BMP_Fonts.Font12x12;
      UI.Texts.Draw_String
           (Buffer,
            Start      => (3, 220),
            Width      => 150,
            Msg        => "pkts/s");

      UI.Texts.Draw_String
           (Buffer,
            Start      => (3, 160),
            Msg        => "bps",
            Width      => 150);

      UI.Texts.Current_Font := BMP_Fonts.Font16x24;
      UI.Texts.Draw_String
           (Buffer,
            Start      => (0, 250),
            Width      => 150,
            Msg        => Image (Display.Speed));

      UI.Texts.Draw_String
           (Buffer,
            Start      => (0, 180),
            Width      => 150,
            Msg        => Format_Bandwidth (Interfaces.Unsigned_32 (Display.Bandwidth)));

      Deadline := Display.Deadline;
   end On_Refresh;

   --  Handle touch events on the display.
   overriding
   procedure On_Touch (Display : in out Display_Type;
                       Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                       States  : in HAL.Touch_Panel.TP_State) is
      use UI.Buttons;
      X : constant Natural := States (States'First).X;
      Y : constant Natural := States (States'First).Y;
   begin
      if UI.Buttons.Contains (Display.Back_Button, X, Y) then
         UI.Displays.Pop_Display;
      end if;
   end On_Touch;

end Hestia.Display.Info;
