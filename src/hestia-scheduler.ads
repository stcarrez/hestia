-----------------------------------------------------------------------
--  hestia-scheduler -- Hestia Scheduler
--  Copyright (C) 2016, 2017, 2018 Stephane Carrez
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

with Hestia.Time;
with Hestia.Ports;
with HAL.Bitmap;

package Hestia.Scheduler is

   --  The schedule state.
   type State_Type is (ON, OFF);

   --  A scheduler day and time.
   type Day_Time is record
      Day     : Hestia.Time.Day_Name;
      Hour    : Hestia.Time.Hour_Number;
      Minute  : Hestia.Time.Minute_Number;
   end record;

   --  Compare two scheduler day and time.
   function "<" (Left, Right : in Day_Time) return Boolean;

   --  Add some minutes to the scheduler day and time.
   function "+" (Date    : in Day_Time;
                 Minutes : in Natural) return Day_Time;

   --  Subtract two scheduler day and time and get the difference in minutes.
   function "-" (Left, Right : in Day_Time) return Integer;

   --  Format the time.
   function Format_Time (Date : in Day_Time) return String;

   Unit : constant Hestia.Time.Minute_Number;

   --  The scheduler index.
   subtype Scheduler_Index is Hestia.Ports.Zone_Type;

   function Get_State (Date : in Hestia.Time.Date_Time;
                       Zone : in Scheduler_Index) return State_Type;

   --  Get the scheduler state for the given day and time.
   function Get_State (Date : in Day_Time;
                       Zone : in Scheduler_Index) return State_Type;

   --  Set the scheduler state for the given day and time.
   procedure Set_State (Date  : in Day_Time;
                        Zone  : in Scheduler_Index;
                        State : in State_Type)
     with Post => Get_State (Date, Zone) = State;

   --  Display the heat schedule on the display based on the current date and time.
   procedure Display (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class;
                      Date   : in Hestia.Time.Date_Time);

private

   Unit : constant Hestia.Time.Minute_Number := 5;

   type Schedule_Unit is new Natural range 0 .. 86_400 / ((Natural (Unit) * 60));

   type Day_Schedule is array (Schedule_Unit) of State_Type with Pack;

   type Week_Schedule is array (Hestia.Time.Day_Name) of Day_Schedule;

   type Schedule_Type is limited record
      Name : String (1 .. 20);
      Week : Week_Schedule;
   end record;

end Hestia.Scheduler;
