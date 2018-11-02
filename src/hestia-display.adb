-----------------------------------------------------------------------
--  hestia-display -- Display manager
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

with STM32.Board;
with Bitmapped_Drawing;
with BMP_Fonts;
with Interfaces;
with UI.Texts;
with Hestia.Network;
with Hestia.Time;
with Net.NTP;
with Hestia.Scheduler;
package body Hestia.Display is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use UI.Texts;
   use type Net.Uint16;

   --  Convert the integer to a string without a leading space.
   function Image (Value : in Net.Uint32) return String;
   function Image (Value : in Net.Uint64) return String;
   function To_Digits (Val : Natural) return String;
   function To_String (H, M, S : Natural) return String;

   Buttons : UI.Buttons.Button_Array (B_MAIN .. B_STAT) :=
     (B_MAIN  => (Name => "Main ", State => UI.Buttons.B_PRESSED, others => <>),
      B_SETUP => (Name => "Setup", others => <>),
      B_STAT  => (Name => "Stats", others => <>));

   --  Kb, Mb, Gb units.
   KB : constant Net.Uint64 := 1024;
   MB : constant Net.Uint64 := KB * KB;
   GB : constant Net.Uint64 := MB * MB;

   --  Convert the integer to a string without a leading space.
   function Image (Value : in Net.Uint32) return String is
      Result : constant String := Net.Uint32'Image (Value);
   begin
      return Result (Result'First + 1 .. Result'Last);
   end Image;

   function Image (Value : in Net.Uint64) return String is
      Result : constant String := Net.Uint64'Image (Value);
   begin
      return Result (Result'First + 1 .. Result'Last);
   end Image;

   Dec_String : constant String := "0123456789";

   function To_Digits (Val : Natural) return String is
      Result : String (1 .. 2);
   begin
      Result (1) := Dec_String (Positive ((Val / 10) + 1));
      Result (2) := Dec_String (Positive ((Val mod 10) + 1));
      return Result;
   end To_Digits;

   function To_String (H, M, S : Natural) return String is
   begin
      return To_Digits (H) & ":" & To_Digits (M) & ":" & To_Digits (S);
   end To_String;

   function Format_Packets (Value : in Net.Uint32) return String is
   begin
      return Net.Uint32'Image (Value);
   end Format_Packets;

   function Format_Bytes (Value : in Net.Uint64) return String is
   begin
      if Value < 10 * KB then
         return Image (Net.Uint32 (Value));
      elsif Value < 10 * MB then
         return Image (Value / KB) & "." & Image (((Value mod KB) * 10) / KB) & "Kb";
      elsif Value < 10 * GB then
         return Image (Value / MB) & "." & Image (((Value mod MB) * 10) / MB) & "Mb";
      else
         return Image (Value / GB) & "." & Image (((Value mod GB) * 10) / GB) & "Gb";
      end if;
   end Format_Bytes;

   function Format_Bandwidth (Value : in Net.Uint32) return String is
   begin
      if Value < Net.Uint32 (KB) then
         return Image (Value);
      elsif Value < Net.Uint32 (MB) then
         return Image (Value / Net.Uint32 (KB)) & "."
           & Image (((Value mod Net.Uint32 (KB)) * 10) / Net.Uint32 (KB)) & "Kbs";
      else
         return Image (Value / Net.Uint32 (MB)) & "."
           & Image (((Value mod Net.Uint32 (MB)) * 10) / Net.Uint32 (MB)) & "Mbs";
      end if;
   end Format_Bandwidth;

   --  ------------------------------
   --  Initialize the display.
   --  ------------------------------
   procedure Initialize is
   begin
      STM32.Board.Display.Initialize;
      STM32.Board.Display.Initialize_Layer (1, HAL.Bitmap.ARGB_1555);

      --  Initialize touch panel
      STM32.Board.Touch_Panel.Initialize;

      for I in Graphs'Range loop
         Use_Graph.Initialize (Graphs (I),
                               X      => 100,
                               Y      => 200,
                               Width  => 380,
                               Height => 72,
                               Rate   => Ada.Real_Time.Milliseconds (1000));
      end loop;
   end Initialize;

   --  ------------------------------
   --  Draw the display buttons.
   --  ------------------------------
   procedure Draw_Buttons (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
   begin
      UI.Buttons.Draw_Buttons (Buffer => Buffer,
                               List   => Buttons,
                               X      => 0,
                               Y      => 0,
                               Width  => 95,
                               Height => 34);
   end Draw_Buttons;

   --  ------------------------------
   --  Draw the layout presentation frame.
   --  ------------------------------
   procedure Draw_Frame (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill;
      Draw_Buttons (Buffer);
      Buffer.Set_Source (Line_Color);
      Buffer.Draw_Vertical_Line (Pt     => (98, 0),
                                 Height => Buffer.Height);
   end Draw_Frame;

   --  ------------------------------
   --  Refresh the graph and draw it.
   --  ------------------------------
   procedure Refresh_Graphs (Buffer     : in out HAL.Bitmap.Bitmap_Buffer'Class;
                             Graph_Mode : in Graph_Kind) is
--        Now     : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
--        EtherScope.Analyzer.Base.Update_Graph_Samples (Samples, True);
--        for I in Samples'Range loop
--           Use_Graph.Add_Sample (Graphs (I), Samples (I), Now);
--        end loop;
      Use_Graph.Draw (Buffer, Graphs (Graph_Mode));
   end Refresh_Graphs;

   --  ------------------------------
   --  Display the current heat schedule and status.
   --  ------------------------------
   procedure Display_Main (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Ref  : constant Net.NTP.NTP_Reference := Hestia.Network.Get_Time;
      T    : Hestia.Time.Date_Time;
   begin
      if Ref.Status in Net.NTP.SYNCED | Net.NTP.RESYNC then
         T := Hestia.Time.Convert (Ref);
         Buffer.Set_Source (UI.Texts.Background);
         Buffer.Fill_Rect (Area => (Position => (100, 0),
                                    Width  => Buffer.Width - 100,
                                    Height => Buffer.Height));
         Hestia.Scheduler.Display (Buffer, T);
      end if;
   end Display_Main;

   --  ------------------------------
   --  Display devices found on the network.
   --  ------------------------------
   procedure Display_Setup (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Y  : constant Natural := 0;
      W  : Natural := Buffer.Width;
   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area => (Position => (100, 0),
                                 Width  => Buffer.Width - 100,
                                 Height => Buffer.Height));

      --  Draw some column header.
      Buffer.Set_Source (Line_Color);
      Buffer.Draw_Horizontal_Line (Pt    => (100, Y + 14),
                                   Width => Buffer.Width - 100);

      UI.Texts.Draw_String (Buffer, (200, 60), 175, "Lundi");
      Buffer.Set_Source (Hot_Color);
      Buffer.Fill_Rect (Area => (Position => (100, 100),
                                 Width  => Buffer.Width - 100,
                                 Height => 40));
      Buffer.Fill_Rect (Area => (Position => (100, 200),
                                 Width  => Buffer.Width - 100,
                                 Height => 40));
      Buffer.Set_Source (HAL.Bitmap.White_Smoke);
      W := W - 100;
      for I in 0 .. 11 loop
         Buffer.Draw_Vertical_Line (Pt     => (100 + (I * W) / 12, 100 - 5),
                                    Height => 5);
         Buffer.Draw_Vertical_Line (Pt     => (100 + (I * W) / 12, 200 - 5),
                                    Height => 5);
      end loop;
      UI.Texts.Foreground := HAL.Bitmap.Green;
      UI.Texts.Current_Font := BMP_Fonts.Font8x8;
      UI.Texts.Draw_String (Buffer, (100, 100 - 10), 175, "0h");
      UI.Texts.Draw_String (Buffer, (100 + 62, 100 - 10), 175, "2h");
      UI.Texts.Draw_String (Buffer, (100 + 62 * 2 - 8, 100 - 10), 175, "4h");
      UI.Texts.Draw_String (Buffer, (100 + 62 * 3 - 8, 100 - 10), 175, "6h");
      UI.Texts.Draw_String (Buffer, (100 + 62 * 4 - 8, 100 - 10), 175, "8h");
      UI.Texts.Draw_String (Buffer, (100 + 62 * 5 - 12, 100 - 10), 175, "10h");

      UI.Texts.Foreground := HAL.Bitmap.Green;
      UI.Texts.Foreground := HAL.Bitmap.White;
   end Display_Setup;

   use Ada.Real_Time;
   Prev_Time : Ada.Real_Time.Time := Ada.Real_Time.Clock;
   Deadline  : Ada.Real_Time.Time := Prev_Time + Ada.Real_Time.Seconds (1);
   Speed      : Net.Uint32 := 0;
   Bandwidth  : Natural := 0;
   Pkts       : Net.Uint32 := 0;
   Bytes      : Net.Uint64 := 0;
   ONE_MS : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (1);

   procedure Display_Time (Buffer   : in out HAL.Bitmap.Bitmap_Buffer'Class;
                           Deadline : out Ada.Real_Time.Time) is
      Ref  : constant Net.NTP.NTP_Reference := Hestia.Network.Get_Time;
      W    : Net.Uint64;
      T    : Hestia.Time.Date_Time;
   begin
      if not (Ref.Status in Net.NTP.SYNCED | Net.NTP.RESYNC) then
         Deadline := Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      else
         T := Hestia.Time.Convert (Ref);
         W := Net.Uint64 (Net.Uint32'Last - T.Sub_Seconds);
         W := Interfaces.Shift_Right (W * 1_000_000, 32);
         Deadline := Ada.Real_Time.Clock + Ada.Real_Time.Microseconds (Integer (W));

         UI.Texts.Current_Font := BMP_Fonts.Font16x24;
         UI.Texts.Draw_String (Buffer, (30, 10), 128, Hestia.Time.Day_Names (T.Week_Day));
         UI.Texts.Draw_String (Buffer, (140, 10), 128, Natural'Image (T.Day));
         UI.Texts.Draw_String (Buffer, (200, 10), 128,
                               Hestia.Time.Month_Names (T.Month) (1 .. 3));
         UI.Texts.Draw_String (Buffer, (300, 10), 175, To_String (T.Hour, T.Minute, T.Second));
         UI.Texts.Current_Font := BMP_Fonts.Font12x12;
      end if;
   end Display_Time;

   --  ------------------------------
   --  Display a performance summary indicator.
   --  ------------------------------
   procedure Display_Summary (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Now       : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      Cur_Pkts  : Net.Uint32;
      Cur_Bytes : Net.Uint64;
      D         : Net.Uint32;
      C         : Net.Uint32;
   begin
      if Deadline < Now then
         Cur_Bytes := Hestia.Network.Ifnet.Rx_Stats.Bytes;
         Cur_Pkts  := Hestia.Network.Ifnet.Rx_Stats.Packets;
         C := Net.Uint32 ((Now - Prev_Time) / ONE_MS);
         D := Net.Uint32 (Cur_Pkts - Pkts);
         Speed := Net.Uint32 (D * 1000) / C;
         Bandwidth := Natural (((Cur_Bytes - Bytes) * 8000) / Net.Uint64 (C));
         Prev_Time := Now;
         Deadline := Deadline + Ada.Real_Time.Seconds (1);
         Pkts := Cur_Pkts;
         Bytes := Cur_Bytes;
      end if;
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area  => (Position => (0, 160),
                                  Width  => 99,
                                  Height => Buffer.Height - 160));

      Bitmapped_Drawing.Draw_String
           (Buffer,
            Start      => (3, 220),
            Msg        => "pkts/s",
            Font       => BMP_Fonts.Font12x12,
            Foreground => UI.Texts.Foreground,
            Background => UI.Texts.Background);

      Bitmapped_Drawing.Draw_String
           (Buffer,
            Start      => (3, 160),
            Msg        => "bps",
            Font       => BMP_Fonts.Font12x12,
            Foreground => UI.Texts.Foreground,
            Background => UI.Texts.Background);

      Bitmapped_Drawing.Draw_String
           (Buffer,
            Start      => (0, 250),
            Msg        => Image (Speed),
            Font       => BMP_Fonts.Font16x24,
            Foreground => UI.Texts.Foreground,
            Background => UI.Texts.Background);

      Bitmapped_Drawing.Draw_String
           (Buffer,
            Start      => (0, 180),
            Msg        => Format_Bandwidth (Interfaces.Unsigned_32 (Bandwidth)),
            Font       => BMP_Fonts.Font16x24,
            Foreground => UI.Texts.Foreground,
            Background => UI.Texts.Background);
   end Display_Summary;

end Hestia.Display;
