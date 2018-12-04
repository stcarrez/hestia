-----------------------------------------------------------------------
--  hestia-display-scheduler -- Display information about the system
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
with Hestia.Time;
with UI.Texts;
package body Hestia.Display.Scheduler is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use UI.Texts;
   use type Net.Uint16;
   use type Hestia.Scheduler.Day_Time;
   use type Hestia.Scheduler.State_Type;
   use Hestia.Scheduler;

   --  Convert the integer to a string without a leading space.
   function Image (Value : in Natural) return String;

   function Image (Value : in Natural) return String is
      Result : constant String := Natural'Image (Value);
   begin
      return Result (Result'First + 1 .. Result'Last);
   end Image;

   use Ada.Real_Time;

   ONE_MS : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (1);

   TOUCH_DELAY : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (600);

   --  ------------------------------
   --  Draw the layout presentation frame.
   --  ------------------------------
   overriding
   procedure On_Restore (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      W  : constant Natural := Buffer.Width;
      H  : constant Natural := Buffer.Height;
      D2 : constant Natural := W / 6;
   begin
      Display.Back_Button.Pos := (0, 0);
      Display.Back_Button.Width := 100;
      Display.Back_Button.Height := 30;
      Display.Slide_Button.Pos := (0, H - 60);
      Display.Slide_Button.Width := W;
      Display.Slide_Button.Height := 60;

      Display.Schedule_Area.Pos := (0, 120);
      Display.Schedule_Area.Width := W;
      Display.Schedule_Area.Height := 80;

      Display.Start_Time.Day := Hestia.Time.Monday;
      Display.Start_Time.Hour := 0;
      Display.Start_Time.Minute := 0;
      Display.Delta_Time := 12 * 24;
      Display.End_Time := Display.Start_Time + Display.Delta_Time;
      Display.Width := W;

      Display.Last_Touch := Ada.Real_Time.Clock;
      Display.Touch_Disable := True;

      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill;
      UI.Texts.Current_Font := BMP_Fonts.Font16x24;
      UI.Texts.Draw_String (Buffer  => Buffer,
                            Start   => Display.Back_Button.Pos,
                            Width   => Display.Back_Button.Width,
                            Msg     => "Back",
                            Justify => UI.Texts.CENTER);

      Display.Deadline := Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (1000);
   end On_Restore;

   function Get_X (Display : in Display_Type;
                   Date    : in Hestia.Scheduler.Day_Time) return Natural is
      R  : Integer := Display.Delta_Time;
      Dt : Integer := Date - Display.Start_Time;
   begin
      Dt := Dt * Display.Width;
      return Dt / R;
   end Get_X;

   function Get_Time (Display : in Display_Type;
                      X       : in Natural) return Day_Time is
      Dt     : constant Natural := (Display.Delta_Time * X) / Display.Width;
   begin
      return Display.Start_Time + Dt;
   end Get_Time;

   --  Refresh the current display.
   overriding
   procedure On_Refresh (Display  : in out Display_Type;
                         Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                         Deadline : out Ada.Real_Time.Time) is
      use type Net.Uint32;
      W : constant Natural := Buffer.Width;
      H : constant Natural := Buffer.Height;
      D : constant Natural := W / 24;
      D2 : constant Natural := W / 6;
      Now       : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      Start     : Hestia.Scheduler.Day_Time;
      X1, X2    : Natural;
      Prev      : Hestia.Scheduler.State_Type;
      New_State : Hestia.Scheduler.State_Type;
   begin
      Buffer.Set_Source (Line_Color);
      Buffer.Fill_Rect ((Position => (0, 60 - 3),
                         Width    => W,
                         Height   => 3));
      Buffer.Fill_Rect ((Position => (0, 120),
                         Width    => W,
                         Height   => 2));
      Buffer.Fill_Rect ((Position => (0, 200),
                         Width    => W,
                         Height   => 2));

      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect ((Position => (0, 100),
                         Width    => W,
                         Height   => 16));

      Buffer.Set_Source (Hot_Color);
      Buffer.Fill_Rect ((Position => (120, 121),
                         Width    => 150,
                         Height   => 78));

      Buffer.Fill_Rect ((Position => (W - 70, 121),
                         Width    => 69,
                         Height   => 78));

      UI.Texts.Current_Font := BMP_Fonts.Font16x24;
      Start := Display.Get_Time (W / 2);
      UI.Texts.Draw_String (Buffer,
                            Start      => (0, 70),
                            Width      => W,
                            Msg        => Hestia.Time.Day_Names (Start.Day),
                           Justify     => UI.Texts.CENTER);

      UI.Texts.Current_Font := BMP_Fonts.Font12x12;

      Start := Display.Start_Time;
      while Start < Display.End_Time loop
         New_State := Hestia.Scheduler.Get_State (Start, Display.Port);
         X1 := Display.Get_X (Start);
         X2 := Display.Get_X (Start + Hestia.Scheduler.Unit);

         if New_State /= Prev and X1 - 20 + 100 < W and X1 > 20 then
            UI.Texts.Draw_String (Buffer,
                                  Start      => (X1 - 20, 100),
                                  Width      => 100,
                                  Msg        => Hestia.Scheduler.Format_Time (Start));
         end if;
         if New_State = Hestia.Scheduler.ON then
            Buffer.Set_Source (Hot_Color);
         else
            Buffer.Set_Source (Cold_Color);
         end if;
         Buffer.Fill_Rect ((Position => (X1, 121),
                            Width    => X2 - X1,
                            Height   => 78));
         Prev := New_State;
         Start := Start + Hestia.Scheduler.Unit;
      end loop;
      if Display.Touch_Disable and Now - Display.Last_Touch < TOUCH_DELAY then
         Display.Touch_Disable := False;
      end if;
      Deadline := Display.Deadline;
   end On_Refresh;

   --  Handle touch events on the display.
   overriding
   procedure On_Touch (Display : in out Display_Type;
                       Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                       States  : in HAL.Touch_Panel.TP_State) is
      use UI.Buttons;
      Now : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      X : constant Natural := States (States'First).X;
      Y : constant Natural := States (States'First).Y;
      Dx : Integer;
      Dy : Integer;
   begin
      if UI.Buttons.Contains (Display.Back_Button, X, Y) then
         UI.Displays.Pop_Display;

      elsif UI.Buttons.Contains (Display.Slide_Button, X, Y) then
         if States'Length > 0 then
            Dx := States (States'Last).X - X;
            Dy := States (States'Last).Y - Y;
            if Dx > 0 then
               Display.Start_Time := Display.Start_Time + Hestia.Scheduler.Unit;
               Display.End_Time := Display.End_Time + Hestia.Scheduler.Unit;
            elsif Dx < 0 then
               Display.Start_Time := Display.Start_Time + Hestia.Scheduler.Unit;
               Display.End_Time := Display.End_Time + Hestia.Scheduler.Unit;
            end if;
         end if;

      elsif UI.Buttons.Contains (Display.Schedule_Area, X, Y) and not Display.Touch_Disable then
         if Now - Display.Last_Touch > TOUCH_DELAY then
            if Hestia.Scheduler.Get_State (Display.Get_Time (X), Display.Port) = ON then
               Display.Last_State := OFF;
            else
               Display.Last_State := ON;
            end if;
         end if;
         Display.Last_Touch := Now;
         for Dx in -4 .. 4 loop
            if X >= Dx and X + Dx < Display.Width then
               declare
                  T : Day_Time := Display.Get_Time (X + Dx);
               begin
                  Hestia.Scheduler.Set_State (T, Display.Port, Display.Last_State);
               end;
            end if;
         end loop;
         Display.Refresh (Buffer, UI.Displays.REFRESH_BOTH);

      end if;
   end On_Touch;

   --  Set the zone for the schedule.
   procedure Set_Zone (Display : in out Display_Type;
                       Port    : in Ports.Zone_Type) is
   begin
      Display.Port := Port;
   end Set_Zone;

end Hestia.Display.Scheduler;
