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
with BMP_Fonts;
with UI.Texts;
with UI.Clocks;
with Hestia.Display.Instances;
package body Hestia.Display.Main is

   procedure Draw_Zone_Button (Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                               Button  : in UI.Buttons.Button_Type);

   procedure Draw_Zone_Button (Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                               Button  : in UI.Buttons.Button_Type) is
      use type UI.Buttons.Button_State;
   begin
      if Button.State = UI.Buttons.B_PRESSED then
         Buffer.Set_Source (Hot_Color);
         UI.Texts.Background := Hot_Color;
      else
         Buffer.Set_Source (Cold_Color);
         UI.Texts.Background := Cold_Color;
      end if;
      Buffer.Fill_Rect ((Position => Button.Pos,
                         Width    => Button.Width,
                         Height   => Button.Height));
      UI.Texts.Current_Font := BMP_Fonts.Font16x24;
      if Button.State = UI.Buttons.B_PRESSED then
         UI.Texts.Draw_String (Buffer  => Buffer,
                               Start   => (Button.Pos.X, Button.Pos.Y - 12 + Button.Height / 2),
                               Width   => Button.Width,
                               Msg     => "ON",
                               Justify => UI.Texts.CENTER);
      else
         UI.Texts.Draw_String (Buffer  => Buffer,
                               Start   => (Button.Pos.X, Button.Pos.Y - 12 + Button.Height / 2),
                               Width   => Button.Width,
                               Msg     => "OFF",
                               Justify => UI.Texts.CENTER);
      end if;
      UI.Texts.Background := HAL.Bitmap.Black;
   end Draw_Zone_Button;

   --  ------------------------------
   --  Draw the layout presentation frame.
   --  ------------------------------
   overriding
   procedure On_Restore (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      W : constant Natural := Buffer.Width;
      H : constant Natural := Buffer.Height;
      M : constant Natural := W / 2;
   begin
      --  Info button on top right.
      Display.Info_Button.Pos := (W - 30, 0);
      Display.Info_Button.Width := 30;
      Display.Info_Button.Height := 30;
      Display.Info_Button.Len := 3;

      --  Zone buttons
      Display.Zone1_Button.Pos := (1, 180 - 30);
      Display.Zone1_Button.Width := 60;
      Display.Zone1_Button.Height := 60;
      Display.Zone2_Button.Pos := (W - 60, 180 - 30);
      Display.Zone2_Button.Width := 60;
      Display.Zone2_Button.Height := 60;

      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill;
      Buffer.Set_Source (Line_Color);
      Buffer.Fill_Rect ((Position => (0, 60),
                         Width    => W,
                         Height   => 3));
      Buffer.Fill_Rect ((Position => (M, 60),
                         Width    => 3,
                         Height   => H - 60));

      UI.Texts.Current_Font := BMP_Fonts.Font16x24;
      UI.Texts.Draw_String (Buffer  => Buffer,
                            Start   => (0, W - 16),
                            Width   => 16,
                            Msg     => "I",
                            Justify => UI.Texts.LEFT);
      UI.Texts.Draw_String (Buffer  => Buffer,
                            Start   => (0, 70),
                            Width   => M - 1,
                            Msg     => "Zone 1",
                            Justify => UI.Texts.CENTER);
      UI.Texts.Draw_String (Buffer  => Buffer,
                            Start   => (M, 70),
                            Width   => M - 1,
                            Msg     => "Zone 2",
                            Justify => UI.Texts.CENTER);
      UI.Clocks.Draw_Clock (Buffer, Center => (M - 90, 180), Width => 80);
      UI.Clocks.Draw_Clock (Buffer, Center => (M + 90, 180), Width => 80);
   end On_Restore;

   --  ------------------------------
   --  Handle touch events on the display.
   --  ------------------------------
   overriding
   procedure On_Touch (Display : in out Display_Type;
                       Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                       States  : in HAL.Touch_Panel.TP_State) is
      use UI.Buttons;
      X : constant Natural := States (States'First).X;
      Y : constant Natural := States (States'First).Y;
   begin
      if UI.Buttons.Contains (Display.Info_Button, X, Y) then
         UI.Displays.Push_Display (Instances.Info_Display'Access);

         --  Toggle Zone1
      elsif UI.Buttons.Contains (Display.Zone1_Button, X, Y) then
         Display.Zone1_Button.State
           := (if Display.Zone1_Button.State = B_PRESSED then B_RELEASED else B_PRESSED);
         Display.Refresh (Buffer, UI.Displays.REFRESH_BOTH);

         --  Toggle Zone2
      elsif UI.Buttons.Contains (Display.Zone2_Button, X, Y) then
         Display.Zone2_Button.State
           := (if Display.Zone2_Button.State = B_PRESSED then B_RELEASED else B_PRESSED);
         Display.Refresh (Buffer, UI.Displays.REFRESH_BOTH);
      end if;
   end On_Touch;

   Cur_Hour : Natural := 0;
   Cur_Min  : Natural := 0;
   Cur_Sec  : Natural := 0;

   --  ------------------------------
   --  Refresh the current display.
   --  ------------------------------
   overriding
   procedure On_Refresh (Display  : in out Display_Type;
                         Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                         Deadline : out Ada.Real_Time.Time) is
      W : constant Natural := Buffer.Width;
      H : constant Natural := Buffer.Height;
      M : constant Natural := W / 2;
   begin
      Draw_Zone_Button (Buffer, Display.Zone1_Button);
      Draw_Zone_Button (Buffer, Display.Zone2_Button);
      UI.Clocks.Draw_Clock (Buffer, Center => (M - 90, 180), Width => 80);
      UI.Clocks.Draw_Clock_Tick (Buffer, (M - 90, 180), 80, Cur_Hour,
                                 Cur_Min, Cur_Sec, UI.Clocks.HOUR_HAND);
      UI.Clocks.Draw_Clock_Tick (Buffer, (M - 90, 180), 80, Cur_Hour,
                                 Cur_Min, Cur_Sec, UI.Clocks.MINUTE_HAND);
      Cur_Min := Cur_Min + 1;
      if Cur_Min = 60 then
         Cur_Min := 0;
         Cur_Hour := (Cur_Hour + 1) mod 24;
      end if;
      Hestia.Display.Display_Time (Buffer, Deadline);
   end On_Refresh;

end Hestia.Display.Main;
