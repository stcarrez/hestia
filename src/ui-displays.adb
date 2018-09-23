-----------------------------------------------------------------------
--  ui-displays -- Utilities to draw text strings
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

package body UI.Displays is

   --  ------------------------------
   --  Initialize the display.
   --  ------------------------------
   procedure Initialize is
   begin
      STM32.Board.Display.Initialize;
      STM32.Board.Display.Initialize_Layer (1, HAL.Bitmap.ARGB_1555);

      --  Initialize touch panel
      STM32.Board.Touch_Panel.Initialize;
   end Initialize;

   --  ------------------------------
   --  Returns True if a refresh is needed.
   --  ------------------------------
   function Need_Refresh (Display : in Display_Type) return Boolean is
   begin
      return Display.Refresh_Flag;
   end Need_Refresh;

   function Handle_Buttons (Display : in out Display_Type'Class;
                            Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                            List    : in out UI.Buttons.Button_Array)
                            return UI.Buttons.Button_Event is
      use type UI.Buttons.Button_Event;

      Event : UI.Buttons.Button_Event;
   begin
      UI.Buttons.Get_Event (Buffer => Buffer,
                            Touch  => STM32.Board.Touch_Panel,
                            List   => List,
                            Event  => Event);
      if Event /= UI.Buttons.NO_EVENT then
         UI.Buttons.Set_Active (List, Event, Display.Button_Changed);

         --  Update the buttons in the first layer.
         if Display.Button_Changed then
            Display.Draw_Buttons (Buffer);
         end if;
      end if;
      return Event;
   end Handle_Buttons;

   --  ------------------------------
   --  Process touch panel event if there is one.
   --  ------------------------------
   procedure Process_Event (Display : in out Display_Type;
                            Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is

   begin
      --  We updated the buttons in the previous layer and
      --  we must update them in the second one.
      if Display.Button_Changed then
         Display_Type'Class (Display).Draw_Buttons (Buffer);
         Display.Button_Changed := False;
      end if;

      Display_Type'Class (Display).Process_Event (Buffer  => Buffer,
                                                  Process => Handle_Buttons'Access);

      --  Update the buttons in the first layer.
      if Display.Button_Changed then
         Display_Type'Class (Display).Draw_Buttons (Buffer);
      end if;
   end Process_Event;

   Top_Display : access Display_Type'Class;

   --  ------------------------------
   --  Push a new display.
   --  ------------------------------
   procedure Push_Display (Display : in Display_Access) is
   begin
      Display.Previous := Display;
      Top_Display := Display;
   end Push_Display;

   --  ------------------------------
   --  Pop the display to go back to the previous one.
   --  ------------------------------
   procedure Pop_Display is
   begin
      Top_Display := Top_Display.Previous;
   end Pop_Display;

   --  ------------------------------
   --  Get the current display.
   --  ------------------------------
   function Current_Display return Display_Access is
   begin
      return Top_Display.all'Access;
   end Current_Display;

end UI.Displays;
