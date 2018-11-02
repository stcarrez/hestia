-----------------------------------------------------------------------
--  hestia-display-info -- Display information about the system
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
package Hestia.Display.Info is

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

private

   type Display_Type is limited new UI.Displays.Display_Type with record
      Back_Button : UI.Buttons.Button_Type;
      Prev_Time   : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      Deadline    : Ada.Real_Time.Time;
      Speed       : Net.Uint32 := 0;
      Bandwidth   : Natural := 0;
      Pkts        : Net.Uint32 := 0;
      Bytes       : Net.Uint64 := 0;
   end record;

end Hestia.Display.Info;
