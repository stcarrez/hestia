-----------------------------------------------------------------------
--  hestia-main -- Hestia main program
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
with Interfaces;

with Ada.Real_Time;

with STM32.Board;
with HAL.Bitmap;

with UI.Buttons;
with Hestia.Network;
with Hestia.Display;
with Hestia.Ports;

--  The main EtherScope task must run at a lower priority as it takes care
--  of displaying results on the screen while the EtherScope receiver's task
--  waits for packets and analyzes them.  All the hardware initialization must
--  be done here because STM32.SDRAM is not protected against concurrent accesses.
procedure Hestia.Main is --  with Priority => System.Priority'First is

   use type Interfaces.Unsigned_32;
   use type UI.Buttons.Button_Index;
   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;

   --  Display refresh period.
   REFRESH_PERIOD   : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (500);

   --  Display refresh deadline.
   Refresh_Deadline : Ada.Real_Time.Time;

   --  The network processing deadline.
   Net_Deadline     : Ada.Real_Time.Time;

   Time_Deadline    : Ada.Real_Time.Time;

   --  Current display mode.
   Mode             : UI.Buttons.Button_Event := Hestia.Display.B_MAIN;
   Button_Changed   : Boolean := False;

   --  Display the Ethernet graph (all traffic).
   --  Graph_Mode       : Hestia.Display.Graph_Kind := Hestia.Display.G_ZONE1;
begin
   --  Initialize the display and draw the main/fixed frames in both buffers.
   Hestia.Display.Initialize;
   Hestia.Ports.Initialize;
   Hestia.Display.Draw_Frame (STM32.Board.Display.Hidden_Buffer (1).all);
   STM32.Board.Display.Update_Layer (1);
   Hestia.Display.Draw_Frame (STM32.Board.Display.Hidden_Buffer (1).all);

   --  Initialize and start the network stack.
   Hestia.Network.Initialize;

   Refresh_Deadline := Ada.Real_Time.Clock + REFRESH_PERIOD;

   --  Loop to retrieve the analysis and display them.
   loop
      declare
         Action  : UI.Buttons.Button_Event;
         Now     : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
         Buffer  : constant HAL.Bitmap.Any_Bitmap_Buffer := STM32.Board.Display.Hidden_Buffer (1);
      begin
         --  We updated the buttons in the previous layer and
         --  we must update them in the second one.
         if Button_Changed then
            Hestia.Display.Draw_Buttons (Buffer.all);
            Button_Changed := False;
         end if;

         --  Check for a button being pressed.
         UI.Buttons.Get_Event (Buffer => Buffer.all,
                               Touch  => STM32.Board.Touch_Panel,
                               List   => Hestia.Display.Buttons,
                               Event  => Action);
         if Action /= UI.Buttons.NO_EVENT then
            Mode := Action;
            UI.Buttons.Set_Active (Hestia.Display.Buttons, Action, Button_Changed);

            --  Update the buttons in the first layer.
            if Button_Changed then
               Hestia.Display.Draw_Buttons (Buffer.all);
            end if;
         end if;

         --  Refresh the display only every 500 ms or when the display state is changed.
         if Refresh_Deadline <= Now or Button_Changed then
            case Mode is
               when Hestia.Display.B_MAIN =>
                  Hestia.Display.Display_Main (Buffer.all);
                  --  Graph_Mode := Hestia.Display.G_ZONE1;
                  --  Hestia.Display.Refresh_Graphs (Buffer.all, Graph_Mode);

               when Hestia.Display.B_SETUP =>
                  Hestia.Display.Display_Setup (Buffer.all);
                  --  Graph_Mode := Hestia.Display.G_ZONE2;

               when others =>
                  null;

            end case;
            Hestia.Display.Display_Summary (Buffer.all);
            Refresh_Deadline := Refresh_Deadline + REFRESH_PERIOD;
            Hestia.Display.Display_Time (Buffer.all, Time_Deadline);
            if Time_Deadline < Refresh_Deadline then
               Refresh_Deadline := Time_Deadline;
            end if;
            STM32.Board.Display.Update_Layer (1);
         end if;
         Hestia.Network.Process (Net_Deadline);
         delay until Now + Ada.Real_Time.Milliseconds (100);
      end;
   end loop;

end Hestia.Main;
