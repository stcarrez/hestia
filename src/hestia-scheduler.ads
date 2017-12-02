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

with Hestia.Time;
with HAL.Bitmap;

package Hestia.Scheduler is

   --  The schedule state.
   type State_Type is (ON, OFF);

   --  The scheduler index.
   type Scheduler_Index is new Natural range 1 .. 2;

   function Get_State (Date : in Hestia.Time.Date_Time;
                       Zone : in Scheduler_Index) return State_Type;

   --  Display the heat schedule on the display based on the current date and time.
   procedure Display (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class;
                      Date   : in Hestia.Time.Date_Time);

private

   type Schedule_Unit is new Natural range 0 .. 86_400 / (5 * 60);

   type Day_Schedule is array (Schedule_Unit) of State_Type with Pack;

   type Week_Schedule is array (Hestia.Time.Day_Name) of Day_Schedule;

   type Schedule_Type is limited record
      Week : Week_Schedule;
   end record;

end Hestia.Scheduler;
