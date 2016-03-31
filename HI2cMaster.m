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

classdef HI2cMaster < handle
    properties (Access = public)
        deviceNumber = 0;
        slaveAddress7Bit = 0;
        clock_Hz = 100e3;
        timeout_ms = 3000;
        usbLatencyTime_ms = 1;
    end
    
    properties (Access = private)
        ftHandle
        ftIsLoaded = false
        ftIsOpen = false
        ftIsInitialized = false
        
        %%% command to set I2C lines idle
        commandI2cLinesIdle = [...
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0011'), ... all pins are high
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE];
        
        %%% command to set I2C start condition
        commandI2cStart = [...
            repmat([... Repeat commands to ensure the minimum period of the start hold time (600ns) is achieved
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0011'), ... set SDA and SCL high to start I2C-communication
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE ...
            ], 1, 4) ...
            ...
            repmat([... Repeat commands to ensure the minimum period of the start setup time (600ns) is achieved
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0001'), ... after set SDA low to start I2C-communication
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE ...
            ], 1, 4) ...
            ...
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0000'), ... after set SDA and SCL low to start I2C-communication
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE];
        
        %%% command to set I2C stop condition
        commandI2cStop = [...
            repmat([...  Repeat commands to ensure the minimum period of the stop setup time (600ns) is achieved
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0000'), ... set SDA low, SCL low to stop I2C-communication
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE ...
            ], 1, 4) ...
            ...
            repmat([...  Repeat commands to ensure the minimum period of the stop setup time (600ns) is achieved
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0001'), ... set SDA low and SCL high to stop I2C-communication
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE ...
            ], 1, 4) ...
            ...
            repmat([...  Repeat commands to ensure the minimum period of the stop hold time (600ns) is achieved
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0011'), ... set SDA and SCL high to stop I2C-communication
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE ...
            ], 1, 4)];
        
        %%% command to write via SDA
        commandSdaWrite = [...
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0000'), ...
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_WRITE];
        
        %%% command to read via SDA
        commandSdaRead = [...
            BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
            bin2dec('0000 0010'), ...
            BusDriver.PARAMETER.MPSSE_IO_DIRECTION_I2C_READ];
        
        %%% command to read byte and send NAK
        commandReadByteAndSendNak = zeros(1,12);
    end
    
    methods (Access = public)
        function status = open(obj)
            BusDriver.loadLibrary();
            obj.ftIsLoaded = true;
            
            [status, obj.ftHandle] = BusDriver.ftOpen(obj.deviceNumber);
            if status; return; end
            obj.ftIsOpen = true;
            
            status = BusDriver.ftResetDevice(obj.ftHandle);
            if status; return; end
            
            mask = bitor(BusDriver.PARAMETER.FT_PURGE_RX, BusDriver.PARAMETER.FT_PURGE_TX, 'uint16');
            status = BusDriver.ftPurge(obj.ftHandle, mask);
            if status; return; end
            
            inTransferSize = 65535;
            outTransferSize = 65535;
            status = BusDriver.ftSetUsbParameters(obj.ftHandle, inTransferSize, outTransferSize);
            if status; return; end
            
            %%% Disable event and error characters
            eventCharacter = false;
            eventCharacterEnabled = 0;
            errorCharacter = false;
            errorCharacterEnabled  = 0;
            status = BusDriver.ftSetChars(obj.ftHandle, eventCharacter, eventCharacterEnabled, errorCharacter, errorCharacterEnabled);
            if status; return; end
            
            readTimeout_ms  = obj.timeout_ms;
            writeTimeout_ms = obj.timeout_ms;
            status = BusDriver.ftSetTimeouts(obj.ftHandle, readTimeout_ms, writeTimeout_ms);
            if status; return; end
            
            status = BusDriver.ftSetLatencyTimer(obj.ftHandle, obj.usbLatencyTime_ms);
            if status; return; end
            
            %%% Reset the MPSSE controller
            mask = 0;
            mode = 0;
            status = BusDriver.ftSetBitMode(obj.ftHandle, mask, mode);
            if status; return; end
            
            %%% Enable the MPSSE controller
            mask = 0;
            mode = 2;
            status = BusDriver.ftSetBitMode(obj.ftHandle, mask, mode);
            if status; return; end
            
            %% Determining wheter MPSSE is in sync by the help of "bad command detection"
            %%% Enable internal loop-back
            opCode = BusDriver.PARAMETER.MPSSE_LOOPBACK_ENABLE;
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            %%% Synchronize MPSSE with bogus command
            opCode = BusDriver.PARAMETER.MPSSE_BOGUS_COMMAND;
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            numBytesToRead = 2;
            [status, dataRx] = BusDriver.ftRead(obj.ftHandle, numBytesToRead);
            if status; return; end
            expectedDaraTx = [BusDriver.PARAMETER.MPSSE_BAD_COMMAND; BusDriver.PARAMETER.MPSSE_BOGUS_COMMAND];
            if ~isequal(dataRx, expectedDaraTx); status = 20; return; end
            
            %%% Disable internal loop-back
            opCode = BusDriver.PARAMETER.MPSSE_LOOPBACK_DISABLE;
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            %%% 60MHz master Clock, Adaptive Clocking off, 3-Phase Clocking on
            opCode = [...
                BusDriver.PARAMETER.MPSSE_60MHZ_CLOCK, ...
                BusDriver.PARAMETER.MPSSE_DISABLE_ADAPTIVE_CLOCKING, ...
                BusDriver.PARAMETER.MPSSE_ENABLE_3_PHASE_CLOCKING];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            %%% Set Divisor: AN_135_MPSSE_Basics.pdf
            %%% Due to 3 Phase Clocking increase the clock by 50%
            modifiedClock = obj.clock_Hz*(1+1/2);
            divisor = uint16(60e6/(2*modifiedClock)-1);
            divisorLowHigh = typecast(divisor, 'uint8');
            opCode = [...
                BusDriver.PARAMETER.MPSSE_CLOCK_DEVISOR, ...
                divisorLowHigh(1), ...
                divisorLowHigh(2)];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            %%% command to read byte and send NAK
            obj.commandReadByteAndSendNak = [...
                obj.commandSdaRead, BusDriver.PARAMETER.MSB_RISING_BYTE_IN, 0, 0, ... Read byte
                obj.commandSdaWrite, BusDriver.PARAMETER.MSB_FALLING_BIT_OUT, 0, 255]; % Send negative acknowledgement
            
            %% set I2C lines idle
            status = BusDriver.ftWrite(obj.ftHandle, obj.commandI2cLinesIdle);
            if status; return; end
            
            %% Initialization is done
            obj.ftIsInitialized = true;
        end
        
        function status = close(obj)
            %%% set lines idle
            status = BusDriver.ftWrite(obj.ftHandle, obj.commandI2cLinesIdle);
            if status; return; end
            
            %%% after release the driver
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
        
        function [dataRx, status] = read(obj, register, numBytes)
            assert(obj.ftIsInitialized);
            dataRx = zeros(1,numBytes);
            
            totalCommand = [...
                obj.commandI2cLinesIdle, ...
                obj.commandI2cStart, ...
                obj.commandSendByteAndReadAck(2*obj.slaveAddress7Bit), ...
                obj.commandSendByteAndReadAck(register), ...
                obj.commandI2cStart, ...
                obj.commandSendByteAndReadAck(2*obj.slaveAddress7Bit+1)];
            
            for byteIdx = 1:numBytes
                totalCommand = [totalCommand, obj.commandReadByteAndSendNak]; %#ok
            end
            
            totalCommand = [totalCommand, ...
                obj.commandI2cStop, ...
                BusDriver.PARAMETER.MPSSE_SEND_IMMEDIATE];
            
            status = BusDriver.ftWrite(obj.ftHandle, totalCommand);
            if status; return; end
            
            numBytesToRead = 3 + numBytes;
            [status, dataTmp] = BusDriver.ftRead(obj.ftHandle, numBytesToRead);
            if status; return; end
            
            %%% 3x ACK:=0 expected
            slaveAckResponse = dataTmp(1:3);
            dataRx = double(dataTmp(4:end));
            
            if sum(bitget(slaveAckResponse, 1)) ~= 0, status = 20 ; return; end
        end
        
        function status = write(obj, register, dataTx)
            assert(obj.ftIsInitialized);
            
            totalCommand = [...
                obj.commandI2cLinesIdle, ...
                obj.commandI2cStart, ...
                obj.commandSendByteAndReadAck(2*obj.slaveAddress7Bit), ...
                obj.commandSendByteAndReadAck(register)];
            
            totalBytes = numel(dataTx);
            for byteIdx = 1:totalBytes
                totalCommand = [totalCommand, obj.commandSendByteAndReadAck(dataTx(byteIdx))];  %#ok
            end
            
            totalCommand = [totalCommand, ...
                obj.commandI2cStop, ...
                BusDriver.PARAMETER.MPSSE_SEND_IMMEDIATE];
            
            status = BusDriver.ftWrite(obj.ftHandle, totalCommand);
            if status; return; end
            
            numBytesToRead = 2 + totalBytes;
            [status, slaveAckResponse] = BusDriver.ftRead(obj.ftHandle, numBytesToRead);
            if status; return; end
            
            %%% only ACK:=0 expected
            if sum(bitget(slaveAckResponse, 1)) ~= 0, status = 20 ; return; end
        end
    end
    
    methods (Access = private)
        function command = commandSendByteAndReadAck(obj, byte)
            command = [...
                obj.commandSdaWrite, BusDriver.PARAMETER.MSB_FALLING_BYTE_OUT, 0, 0, byte, ... Send byte
                obj.commandSdaRead, BusDriver.PARAMETER.MSB_RISING_BIT_IN, 0]; ... Get acknowledgement
        end
    end
end