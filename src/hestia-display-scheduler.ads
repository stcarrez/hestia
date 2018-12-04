-----------------------------------------------------------------------
--  hestia-display-scheduler -- Display scheduler
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
with HAL.Bitmap;
with HAL.Touch_Panel;
with Ada.Real_Time;
with Net;

with UI.Displays;
with Hestia.Ports;
with Hestia.Scheduler;
package Hestia.Display.Scheduler is

   type Display_Type is limited new UI.Displays.Display_Type with private;

   --  Draw the layout presentation frame.
   overriding
   procedure On_Restore (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class);

   --  Refresh the current display.
   overriding
   procedure On_Refresh (Display  : in out Display_Type;
                         Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                         Deadline : out Ada.Real_Time.Time);

   --  Handle touch events on the display.
   overriding
   procedure On_Touch (Display : in out Display_Type;
                       Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                       States  : in HAL.Touch_Panel.TP_State);

   --  Set the zone for the schedule.
   procedure Set_Zone (Display : in out Display_Type;
                       Port    : in Ports.Zone_Type);

private

   subtype Day_Time is Hestia.Scheduler.Day_Time;

   type Display_Type is limited new UI.Displays.Display_Type with record
      Back_Button   : UI.Buttons.Button_Type;
      Slide_Button  : UI.Buttons.Button_Type;
      Schedule_Area : UI.Buttons.Button_Type;
      Deadline      : Ada.Real_Time.Time;
      Last_Touch    : Ada.Real_Time.Time;
      Touch_Disable : Boolean := True;
      Last_State    : Hestia.Scheduler.State_Type := Hestia.Scheduler.OFF;
      Port          : Ports.Zone_Type := 1;
      Start_Time    : Hestia.Scheduler.Day_Time;
      End_Time      : Hestia.Scheduler.Day_Time;
      Delta_Time    : Integer;
      Width         : Natural;
   end record;

   function Get_X (Display : in Display_Type;
                   Date    : in Hestia.Scheduler.Day_Time) return Natural;

   function Get_Time (Display : in Display_Type;
                      X       : in Natural) return Day_Time;

end Hestia.Display.Scheduler;
