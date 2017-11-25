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
with Net.NTP;

package body Hestia.Display is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use UI.Texts;
   use type Net.Uint16;

   --  Convert the integer to a string without a leading space.
   function Image (Value : in Net.Uint32) return String;
   function Image (Value : in Net.Uint64) return String;
   function To_Digits (Val : Net.Uint32) return String;
   function To_String (H, M, S : Net.Uint32) return String;

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

   function To_Digits (Val : Net.Uint32) return String is
      Result : String (1 .. 2);
   begin
      Result (1) := Dec_String (Positive ((Val / 10) + 1));
      Result (2) := Dec_String (Positive ((Val mod 10) + 1));
      return Result;
   end To_Digits;

   function To_String (H, M, S : Net.Uint32) return String is
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
   --  Display devices found on the network.
   --  ------------------------------
   procedure Display_Devices (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area => (Position => (100, 0),
                                 Width  => Buffer.Width - 100,
                                 Height => Buffer.Height));
   end Display_Devices;

   --  ------------------------------
   --  Display devices found on the network.
   --  ------------------------------
   procedure Display_Protocols (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Y      : constant Natural := 0;

   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area => (Position => (100, 0),
                                 Width  => Buffer.Width - 100,
                                 Height => Buffer.Height));

      --  Draw some column header.
      UI.Texts.Draw_String (Buffer, (100, 30), 250, "Samedi 25 Novembre");
--        UI.Texts.Draw_String (Buffer, (150, Y), 100, "Packets", RIGHT);
--        UI.Texts.Draw_String (Buffer, (250, Y), 100, "Bytes", RIGHT);
--        UI.Texts.Draw_String (Buffer, (350, Y), 100, "BW", RIGHT);
      Buffer.Set_Source (Line_Color);
      Buffer.Draw_Horizontal_Line (Pt    => (100, Y + 14),
                                   Width => Buffer.Width - 100);

      UI.Texts.Draw_String (Buffer, (100, 80), 150, "Chambres");
      Buffer.Set_Source (Cold_Color);
      Buffer.Fill_Rect (Area => (Position => (100, 100),
                                 Width  => Buffer.Width - 100,
                                 Height => 50));

      Buffer.Set_Source (Hot_Color);
      Buffer.Fill_Rect (Area => (Position => (150, 100),
                                 Width  => 50,
                                 Height => 50));
      Buffer.Fill_Rect (Area => (Position => (350, 100),
                                 Width  => 100,
                                 Height => 50));

      UI.Texts.Draw_String (Buffer, (100, 160), 150, "Salon");
      Buffer.Set_Source (Cold_Color);
      Buffer.Fill_Rect (Area => (Position => (100, 180),
                                 Width  => Buffer.Width - 100,
                                 Height => 50));

      Buffer.Set_Source (Hot_Color);
      Buffer.Fill_Rect (Area => (Position => (150, 180),
                                 Width  => 50,
                                 Height => 50));
      Buffer.Fill_Rect (Area => (Position => (350, 180),
                                 Width  => 100,
                                 Height => 50));

      UI.Texts.Foreground := HAL.Bitmap.Green;
      UI.Texts.Foreground := HAL.Bitmap.White;
   end Display_Protocols;

   --  ------------------------------
   --  Display IGMP groups found on the network.
   --  ------------------------------
   procedure Display_Groups (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Y : constant Natural := 0;
   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area => (Position => (100, 0),
                                 Width  => Buffer.Width - 100,
                                 Height => Buffer.Height));

      --  Draw some column header.
      UI.Texts.Draw_String (Buffer, (105, Y), 175, "IP");
      UI.Texts.Draw_String (Buffer, (180, Y), 100, "Packets", RIGHT);
      UI.Texts.Draw_String (Buffer, (280, Y), 100, "Bytes", RIGHT);
      UI.Texts.Draw_String (Buffer, (380, Y), 100, "Bandwidth", RIGHT);
      Buffer.Set_Source (Line_Color);
      Buffer.Draw_Horizontal_Line (Pt    => (100, Y + 14),
                                   Width => Buffer.Width - 100);

      UI.Texts.Foreground := HAL.Bitmap.Green;

      UI.Texts.Foreground := HAL.Bitmap.White;
   end Display_Groups;

   --  ------------------------------
   --  Display TCP/IP information found on the network.
   --  ------------------------------
   procedure Display_TCP (Buffer : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Y : Natural := 0;

   begin
      Buffer.Set_Source (UI.Texts.Background);
      Buffer.Fill_Rect (Area  => (Position => (100, 0),
                                  Width  => Buffer.Width - 100,
                                  Height => Buffer.Height));

      --  Draw some column header.
      UI.Texts.Draw_String (Buffer, (105, Y), 175, "TCP Port");
      UI.Texts.Draw_String (Buffer, (180, Y), 100, "Packets", RIGHT);
      UI.Texts.Draw_String (Buffer, (280, Y), 100, "Bytes", RIGHT);
      UI.Texts.Draw_String (Buffer, (380, Y), 100, "Bandwidth", RIGHT);
      Buffer.Set_Source (Line_Color);
      Buffer.Draw_Horizontal_Line (Pt    => (100, Y + 14),
                                   Width => Buffer.Width - 100);
      Y := Y + 18;

      UI.Texts.Foreground := HAL.Bitmap.Green;
      UI.Texts.Draw_String (Buffer, (105, Y), 175, "All");

      Buffer.Set_Source (Line_Color);
      Buffer.Draw_Horizontal_Line (Pt    => (100, 25),
                                   Width => Buffer.Width - 100);
      UI.Texts.Foreground := HAL.Bitmap.White;
   end Display_TCP;

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
      T    : Net.NTP.NTP_Timestamp;
      H    : Net.Uint32;
      M    : Net.Uint32;
      S    : Net.Uint32;
      W    : Net.Uint64;
   begin
      if not (Ref.Status in Net.NTP.SYNCED | Net.NTP.RESYNC) then
         Deadline := Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      else
         T := Net.NTP.Get_Time (Ref);
         S := T.Seconds mod 86400;
         H := S / 3600;
         S := S mod 3600;
         M := S / 60;
         S := S mod 60;
         W := Net.Uint64 (Net.Uint32'Last - T.Sub_Seconds);
         W := Interfaces.Shift_Right (W * 1_000_000, 32);
         Deadline := Ada.Real_Time.Clock + Ada.Real_Time.Microseconds (Integer (W));

         UI.Texts.Current_Font := BMP_Fonts.Font16x24;
         UI.Texts.Draw_String (Buffer, (105, 60), 175, To_String (H, M, S));
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
