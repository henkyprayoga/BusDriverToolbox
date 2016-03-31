% Copyright (c) 2016, dspKitchen
% All rights reserved.
%
% This code is dual-licensed: you can redistribute it and/or modify
% it under the terms of the GNU General Public License version 2 as
% published by the Free Software Foundation. For the terms of this
% license, see <http://www.gnu.org/licenses/>.
%
% You are free to use this code under the terms of the GNU General
% Public License, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
%
% Alternatively, you can license this code under a commercial
% license, as set out in <http://dspkitchen.com/>.

classdef HGpio < handle
    properties (Access = public)
        deviceNumber    = 0;
        direction       = [HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN];
        clock_Hz        = 9600;
        timeout_ms      = 3000;
    end
    
    properties (Constant = true)
        IN      = 0;
        OUT     = 1;
        LOW     = 0;
        HIGH    = 1;
    end
    
    properties (Access = private)
        ftHandle
        ftIsLoaded          = false;
        ftIsOpen            = false;
        ftIsInitialized     = false;
        lastDataWritten     = 0;
    end
    
    methods
        function status = open(obj)
            BusDriver.loadLibrary();
            obj.ftIsLoaded = true;
            
            [status, obj.ftHandle] = BusDriver.ftOpen(obj.deviceNumber);
            if status; return; end
            obj.ftIsOpen = true;
            
            status = BusDriver.ftResetDevice(obj.ftHandle);
            if status; return; end
            
            inTransferSize = 65535;
            outTransferSize = 65535;
            status = BusDriver.ftSetUsbParameters(obj.ftHandle, inTransferSize, outTransferSize);
            if status; return; end
            
            readTimeout_ms = obj.timeout_ms;
            writeTimeout_ms = obj.timeout_ms;
            status = BusDriver.ftSetTimeouts(obj.ftHandle, readTimeout_ms, writeTimeout_ms);
            if status; return; end
            
            usbLatencyTime_ms = 0;
            status = BusDriver.ftSetLatencyTimer(obj.ftHandle, usbLatencyTime_ms);
            if status; return; end
            
            %%% Reset controller
            mask = 0;
            mode = 0;
            status = BusDriver.ftSetBitMode(obj.ftHandle, mask, mode);
            if status; return; end
            
            %%% Emable Bit-Bang Mode
            
            %%% This sets up which bits are inputs and
            %%% outputs. A bit value of 0 sets the corresponding pin to an input, a bit
            %%% value of 1 sets the corresponding pin to an output.
            directionU8 = uint8(obj.direction);
            mask = uint8(0);
            for bitIdx = 1:8
                mask = bitset(mask, bitIdx, directionU8(bitIdx));
            end
            
            %%% Mode value. Can be one of the following:
            %%% 0x1 = Asynchronous Bit Bang
            mode = BusDriver.PARAMETER.FT_BITMODE_ASYNC_BITBANG;
            status = BusDriver.ftSetBitMode(obj.ftHandle, mask, mode);
            if status; return; end
            
            mask = bitor(BusDriver.PARAMETER.FT_PURGE_RX, BusDriver.PARAMETER.FT_PURGE_TX, 'uint16');
            status = BusDriver.ftPurge(obj.ftHandle, mask);
            if status; return; end
            
            status = BusDriver.ftSetBaudRate(obj.ftHandle, obj.clock_Hz);
            if status; return; end
            
            obj.ftIsInitialized = true;
        end
        
        function status = close(obj)
            if obj.ftIsOpen
                status = BusDriver.ftClose(obj.ftHandle);
                obj.ftIsOpen = false;
                obj.ftIsInitialized = false;
            else
                status = 20;
            end
            
            if obj.ftIsLoaded
                BusDriver.unloadLibrary();
                obj.ftIsLoaded = false;
            else
                status = 20;
            end
        end
        
        function [levelGet, status] = read(obj)
            assert(obj.ftIsInitialized);
            levelGet = zeros(1,8);
            
            [status, dataRxU8] = BusDriver.ftGetBitMode(obj.ftHandle);
            
            for bitIdx = 1:8
                levelGet(bitIdx) = double(bitget(dataRxU8, bitIdx));
            end
        end
        
        function status = write(obj, levelSet)
            assert(obj.ftIsInitialized);
            
            levelSetU8 = uint8(0);
            for bitIdx = 1:8
                levelSetU8 = bitset(levelSetU8, bitIdx, levelSet(bitIdx));
            end
            
            obj.lastDataWritten = levelSetU8;
            status = BusDriver.ftWrite(obj.ftHandle, levelSetU8);
            if status; return; end
        end
    end
end