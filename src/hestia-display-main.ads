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
with HAL.Bitmap;
with Ada.Real_Time;
with Net;

with UI.Buttons;
with UI.Displays;
package Hestia.Display.Main is

   type Display_Type is new UI.Displays.Display_Type with null record;

   --  Process touch panel event if there is one.
   overriding
   procedure Process_Event (Display : in out Display_Type;
                            Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                            Process : not null access
                              function (Display : in out UI.Displays.Display_Type'Class;
                                        Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                                        Buttons : in out UI.Buttons.Button_Array)
                            return UI.Buttons.Button_Event);

   --  Draw the layout presentation frame.
   overriding
   procedure Draw_Frame (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class);

   --  Draw the display buttons.
   overriding
   procedure Draw_Buttons (Display : in out Display_Type;
                           Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class);

   --  Refresh the current display.
   overriding
   procedure Refresh (Display  : in out Display_Type;
                      Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                      Deadline : out Ada.Real_Time.Time);

   --  Display the current heat schedule and status.
   procedure Display_Main (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class);

   Display : aliased Display_Type;

private

   B_ZONE_1  : constant UI.Buttons.Button_Index := 1;
   B_ZONE_2  : constant UI.Buttons.Button_Index := 2;

   Buttons : UI.Buttons.Button_Array (B_ZONE_1 .. B_ZONE_2) :=
     (B_ZONE_1 => (Name => "ON   ", State => UI.Buttons.B_PRESSED, others => <>),
      B_ZONE_2 => (Name => "ON   ", others => <>));

end Hestia.Display.Main;
