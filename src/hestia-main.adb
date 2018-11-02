-----------------------------------------------------------------------
--  hestia-main -- Hestia main program
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

with Ada.Real_Time;

with STM32.Board;
with HAL.Bitmap;

with UI.Displays;
with Hestia.Network;
with Hestia.Display.Instances;
with Hestia.Ports;

--  The main EtherScope task must run at a lower priority as it takes care
--  of displaying results on the screen while the EtherScope receiver's task
--  waits for packets and analyzes them.  All the hardware initialization must
--  be done here because STM32.SDRAM is not protected against concurrent accesses.
procedure Hestia.Main is --  with Priority => System.Priority'First is

   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;

   --  Display refresh period.
   REFRESH_PERIOD   : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (500);

   --  The network processing deadline.
   Net_Deadline     : Ada.Real_Time.Time;

begin
   --  Initialize the display and draw the main/fixed frames in both buffers.
   UI.Displays.Initialize;
   Hestia.Ports.Initialize;

   --  Initialize and start the network stack.
   Hestia.Network.Initialize;

   UI.Displays.Push_Display (Hestia.Display.Instances.Display'Access);

   --  Loop to retrieve the analysis and display them.
   loop
      declare
         Now     : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
         Buffer  : constant HAL.Bitmap.Any_Bitmap_Buffer := STM32.Board.Display.Hidden_Buffer (1);
         Display : UI.Displays.Display_Access := UI.Displays.Current_Display;
      begin
         Display.Process_Event (Buffer.all);

         --  Refresh the display only when it needs.
         Display := UI.Displays.Current_Display;
         if Display.Need_Refresh (Now) then
            Display.Refresh (Buffer.all);
         end if;
         Hestia.Network.Process (Net_Deadline);
         delay until Now + Ada.Real_Time.Milliseconds (100);
      end;
   end loop;

end Hestia.Main;
