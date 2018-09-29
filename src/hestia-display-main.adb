-----------------------------------------------------------------------
--  hestia-display-main -- Main display view manager
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

with STM32.Board;
with Bitmapped_Drawing;
with BMP_Fonts;
with Interfaces;
with UI.Texts;
with UI.Clocks;
with Hestia.Network;
with Hestia.Time;
with Net.NTP;
with Hestia.Scheduler;
package body Hestia.Display.Main is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use UI.Texts;
   use type Net.Uint16;

   --  ------------------------------
   --  Draw the layout presentation frame.
   --  ------------------------------
   procedure Draw_Frame (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      W : constant Natural := Buffer.Width;
      H : constant Natural := Buffer.Height;
      M : constant Natural := W / 2;
   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill;
      Display.Draw_Buttons (Buffer);
      Buffer.Set_Source (Line_Color);
      Buffer.Fill_Rect ((Position => (0, 80),
                         Width    => W,
                         Height   => 3));
      Buffer.Fill_Rect ((Position => (M, 80),
                         Width    => 3,
                         Height   => H - 80));
      UI.Clocks.Draw_Clock (Buffer, Center => (M - 90, 180), Width => 80);
      UI.Clocks.Draw_Clock (Buffer, Center => (M + 90, 180), Width => 80);
   end Draw_Frame;

   --  ------------------------------
   --  Draw the display buttons.
   --  ------------------------------
   procedure Draw_Buttons (Display : in out Display_Type;
                           Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is
   begin
      UI.Buttons.Draw_Buttons (Buffer => Buffer,
                               List   => Buttons,
                               X      => 0,
                               Y      => 0,
                               Width  => 95,
                               Height => 34);
   end Draw_Buttons;

   --  Process touch panel event if there is one.
   overriding
   procedure Process_Event (Display : in out Display_Type;
                            Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                            Process : not null access
                              function (Display : in out UI.Displays.Display_Type'Class;
                                        Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                                        Buttons : in out UI.Buttons.Button_Array)
                            return UI.Buttons.Button_Event) is
      Event : UI.Buttons.Button_Event
        := Process (Display, Buffer, Buttons);
   begin
      null;
   end Process_Event;

   --  Refresh the current display.
   overriding
   procedure Refresh (Display  : in out Display_Type;
                      Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                      Deadline : out Ada.Real_Time.Time) is
   begin
      Display_Main (Buffer);
      --  Display_Summary (Buffer);
      Hestia.Display.Display_Time (Buffer, Deadline);
   end Refresh;

   --  ------------------------------
   --  Display the current heat schedule and status.
   --  ------------------------------
   procedure Display_Main (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Ref  : constant Net.NTP.NTP_Reference := Hestia.Network.Get_Time;
      T    : Hestia.Time.Date_Time;
   begin
      if Ref.Status in Net.NTP.SYNCED | Net.NTP.RESYNC then
         T := Hestia.Time.Convert (Ref);
      end if;
   end Display_Main;

end Hestia.Display.Main;
