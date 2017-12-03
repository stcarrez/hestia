-----------------------------------------------------------------------
--  hestia-scheduler -- Hestia Scheduler
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
with UI.Texts;
package body Hestia.Scheduler is

   type Schedule_Array_Type is array (Scheduler_Index) of Schedule_Type;

   Zones : Schedule_Array_Type;

   Schedule_Middle : constant Schedule_Unit := (Schedule_Unit'Last - Schedule_Unit'First) / 2;

   --  Button colors (inactive).
   Hot_Color        : constant HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Red;
   Cold_Color       : constant HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Blue;
   Now_Color        : constant HAL.Bitmap.Bitmap_Color := HAL.Bitmap.White_Smoke;

   function Get_State (Date : in Hestia.Time.Date_Time;
                       Zone : in Scheduler_Index) return State_Type is
      Pos : Schedule_Unit;
   begin
      Pos := Schedule_Unit (Date.Hour * 12) + Schedule_Unit (Date.Minute / 5);
      return Zones (Zone).Week (Date.Week_Day) (Pos);
   end Get_State;

   --  ------------------------------
   --  Display the heat schedule on the display based on the current date and time.
   --  ------------------------------
   procedure Display (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class;
                      Date   : in Hestia.Time.Date_Time) is
      Pos   : Schedule_Unit;
      Start : Schedule_Unit;
      X     : Natural := 100;
      Y     : Natural := 200;
      W     : constant Natural := Buffer.Width - X;
      Count : constant Natural := Natural (Schedule_Unit'Last - Schedule_Unit'First);

   begin
      Pos := Schedule_Unit (Date.Hour * 12) + Schedule_Unit (Date.Minute / 5);
      for Zone in Zones'Range loop
         if Zones (Zone).Week (Date.Week_Day) (Pos) = ON then
            Hestia.Ports.Set_Zone (Zone, Hestia.Ports.H_CONFORT);
         else
            Hestia.Ports.Set_Zone (Zone, Hestia.Ports.H_ECO);
         end if;
      end loop;
      Y := 185;
      for Zone in Zones'Range loop
         UI.Texts.Draw_String (Buffer, (100, Y), 250, Zones (Zone).Name);
         Y := Y + 30;
      end loop;
      if Pos >= Schedule_Middle then
         Start := Pos - Schedule_Middle;
      else
         Start := Pos + Schedule_Middle;
      end if;
      for I in Schedule_Unit'First .. Schedule_Unit'Last loop
         X := 100 + (Natural (I) * W) / Count;
         Y := 200;
         for Zone in Zones'Range loop
            if Zones (Zone).Week (Date.Week_Day) (Start) = ON then
               Buffer.Set_Source (Hot_Color);
            else
               Buffer.Set_Source (Cold_Color);
            end if;
            if Y + (W / Count) + 1 < W then
               Buffer.Fill_Rect (Area  => (Position => (X, Y),
                                           Width  => (W / Count) + 1,
                                           Height => 10));
            else
               Buffer.Fill_Rect (Area  => (Position => (X, Y),
                                           Width  => (W / Count),
                                           Height => 10));
            end if;
            Y := Y + 30;
         end loop;
         if Start = Schedule_Unit'Last then
            Start := Schedule_Unit'First;
         else
            Start := Start + 1;
         end if;
      end loop;
      Buffer.Set_Source (Now_Color);
      Buffer.Draw_Vertical_Line (Pt     => (100 + W / 2, 200 - 5),
                                 Height => 30 + 30 + 30);
   end Display;

begin
   Zones (1).Name := "Salon               ";
   Zones (2).Name := "Chambres            ";
   Zones (3).Name := "Salles de bains     ";
   for Day in Hestia.Time.Day_Name'Range loop
      --  On from 7:00 to 22:00.
      Zones (1).Week (Day) := (84 .. 264 => ON, others => OFF);

      --  On from 7:00 to 10:00 and 18:00 to 22:00.
      Zones (2).Week (Day) := (84 .. 120 => ON, 216 .. 260 => ON, others => OFF);

      --  On from 7:00 to 10:00 and 18:00 to 22:00.
      Zones (3).Week (Day) := (84 .. 120 => ON, 216 .. 260 => ON, others => OFF);
   end loop;
end Hestia.Scheduler;
