-----------------------------------------------------------------------
--  ui-displays -- Display manager
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
with Ada.Real_Time;

with HAL.Bitmap;
with UI.Buttons;

--  == Display ==
--  The `Display_Type` is a tagged record that defines several operations to handle
--  the main display and its interaction with the user.
package UI.Displays is

   type Display_Type is abstract tagged limited private;
   type Display_Access is not null access all Display_Type'Class;

   --  Returns True if a refresh is needed.
   function Need_Refresh (Display : in Display_Type) return Boolean;

   --  Process touch panel event if there is one.
   procedure Process_Event (Display : in out Display_Type;
                            Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                            Process : not null access
                              function (Display : in out Display_Type'Class;
                                        Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
                                        Buttons : in out UI.Buttons.Button_Array)
                            return UI.Buttons.Button_Event) is abstract;

   --  Process touch panel event if there is one.
   procedure Process_Event (Display : in out Display_Type;
                            Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class);

   --  Refresh the current display.
   procedure Refresh (Display  : in out Display_Type;
                      Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                      Deadline : out Ada.Real_Time.Time) is abstract;

   --  Draw the layout presentation frame.
   procedure Draw_Frame (Display : in out Display_Type;
                         Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is abstract;

   --  Draw the display buttons.
   procedure Draw_Buttons (Display : in out Display_Type;
                           Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class) is abstract;

   procedure Initialize;

   --  Push a new display.
   procedure Push_Display (Display : in Display_Access);

   --  Pop the display to go back to the previous one.
   procedure Pop_Display;

   --  Get the current display.
   function Current_Display return Display_Access;

private

   type Display_Type is abstract tagged limited record
      Refresh_Flag   : Boolean := True;
      Button_Changed : Boolean := True;
      Previous       : access Display_Type;
   end record;

end UI.Displays;
