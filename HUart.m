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

classdef HUart < handle
    properties (Access = public)
        deviceNumber = 0;
        clock_Hz = 9600;
        timeout_ms = 3000;
        usbLatencyTime_ms = 1;
    end
    
    properties (Access = private)
        ftHandle
        ftIsLoaded          = false;
        ftIsOpen            = false;
        ftIsInitialized     = false;
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
            
            status = BusDriver.ftSetBitMode(obj.ftHandle, ...
                BusDriver.PARAMETER.DO_NOT_CARE, ...
                BusDriver.PARAMETER.FT_BITMODE_RESET);
            if status; return; end
            
            status = BusDriver.ftClrRts(obj.ftHandle);
            if status; return; end
            
            status = BusDriver.ftSetBaudRate(obj.ftHandle, obj.clock_Hz);
            if status; return; end
            
            inTransferSize = 65535;
            outTransferSize = 65535;
            status = BusDriver.ftSetUsbParameters(obj.ftHandle, inTransferSize, outTransferSize);
            if status; return; end
            
            readTimeout_ms = obj.timeout_ms;
            writeTimeout_ms = obj.timeout_ms;
            status = BusDriver.ftSetTimeouts(obj.ftHandle, readTimeout_ms, writeTimeout_ms);
            if status; return; end
            
            status = BusDriver.ftSetLatencyTimer(obj.ftHandle, obj.usbLatencyTime_ms);
            if status; return; end
            
            status = BusDriver.ftSetDataCharacteristics(obj.ftHandle, ...
                BusDriver.PARAMETER.FT_BITS_8, ...
                BusDriver.PARAMETER.FT_STOP_BITS_1, ...
                BusDriver.PARAMETER.FT_PARITY_NONE);
            if status; return; end
            
            status = BusDriver.ftSetFlowControl(obj.ftHandle, ...
                BusDriver.PARAMETER.FT_FLOW_NONE, ...
                BusDriver.PARAMETER.DO_NOT_CARE, ...
                BusDriver.PARAMETER.DO_NOT_CARE);
            if status; return; end
            
            mask = bitor(BusDriver.PARAMETER.FT_PURGE_RX, BusDriver.PARAMETER.FT_PURGE_TX, 'uint16');
            status = BusDriver.ftPurge(obj.ftHandle, mask);
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
        
        function [dataRx, status] = writeRead(obj, dataTx)
            assert(obj.ftIsInitialized, 'Device not initialized')
            dataRx = zeros(size(dataTx), 'double');
            
            status = obj.write(dataTx);
            if status; return; end
            
            numBytesToRead = numel(dataTx);
            [dataRxU8, status] = obj.read(numBytesToRead);
            if status; return; end
            
            dataRx = double(dataRxU8);
        end
        
        function status = write(obj, dataTx)
            assert(obj.ftIsInitialized, 'Device not initialized')
            
            status = BusDriver.ftWrite(obj.ftHandle, uint8(dataTx(:)));
            if status; return; end
        end
        
        function [dataRx, status] = read(obj, numBytesToRead)
            assert(obj.ftIsInitialized, 'Device not initialized')
            dataRx = zeros(numBytesToRead, 1, 'double');
            
            [status, dataRxU8] = BusDriver.ftRead(obj.ftHandle, numBytesToRead);
            if status; return; end
            
            dataRx = double(dataRxU8);
        end
    end
end