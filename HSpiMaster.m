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

classdef HSpiMaster < handle
    properties (Access = public)
        deviceNumber = 1;
        spiMode = 0;
        clock_Hz = 1e6;
        usbLatencyTime_ms = 1;
        timeout_ms = 3000;
        waitOnInterrupt = 0; %% 0:Disable; -1:I/O Level Low; +1:I/O Level High
    end
    
    properties (Access = private)
        ftHandle
        headerRw            = 0;
        headerR             = 0;
        headerW             = 0;
        headerWaitIoState   = 0;
        chipSelectEnable    = [0 0 0];
        chipSelectDisable   = [0 0 0];
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
            
            readTimeout_ms = obj.timeout_ms;
            writeTimeout_ms = obj.timeout_ms;
            status = BusDriver.ftSetTimeouts(obj.ftHandle, readTimeout_ms, writeTimeout_ms);
            if status; return; end
            
            status = BusDriver.ftSetLatencyTimer(obj.ftHandle, obj.usbLatencyTime_ms);
            if status; return; end
            
            %%% Reset the MPSSE controller
            mask = 0;
            mode = BusDriver.PARAMETER.FT_BITMODE_RESET;
            status = BusDriver.ftSetBitMode(obj.ftHandle, mask, mode);
            if status; return; end
            
            %%% Enable the MPSSE controller
            mask = 0;
            mode = BusDriver.PARAMETER.FT_BITMODE_MPSSE;
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
            
            %% MPSSE Setup
            %%% 60MHz master Clock, Adaptive Clocking off, 3-Phase Clocking off
            opCode = [...
                BusDriver.PARAMETER.MPSSE_60MHZ_CLOCK, ...
                BusDriver.PARAMETER.MPSSE_DISABLE_ADAPTIVE_CLOCKING, ...
                BusDriver.PARAMETER.MPSSE_DISABLE_3_PHASE_CLOCKING];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            %%% Set Divisor: AN_135_MPSSE_Basics.pdf
            divisor = uint16(60e6/(2*obj.clock_Hz)-1);
            divisorLowHigh = typecast(divisor, 'uint8');
            opCode = [BusDriver.PARAMETER.MPSSE_CLOCK_DEVISOR, divisorLowHigh(1), divisorLowHigh(2)];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            %%% Compose header, preamble
            switch obj.spiMode
                case 0
                    %%% Set default SPI level
                    opCode = [...
                        BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
                        bin2dec('1100'), ...
                        BusDriver.PARAMETER.MPSSE_IO_DIRECTION_SPI];
                    
                    status = BusDriver.ftWrite(obj.ftHandle, opCode);
                    if status; return; end
                    
                    obj.headerRw = BusDriver.PARAMETER.MSB_RISING_BYTE_IN_FALLING_BYTE_OUT;
                    obj.headerR  = BusDriver.PARAMETER.MSB_RISING_BYTE_IN;
                    obj.headerW  = BusDriver.PARAMETER.MSB_FALLING_BYTE_OUT;
                    
                    obj.chipSelectEnable = [...
                        BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
                        bin2dec('0100'), ...
                        BusDriver.PARAMETER.MPSSE_IO_DIRECTION_SPI];
                    
                    obj.chipSelectDisable = [...
                        BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
                        bin2dec('1100'), ...
                        BusDriver.PARAMETER.MPSSE_IO_DIRECTION_SPI];
                    
                case 2
                    %%% Set default SPI level
                    opCode = [...
                        BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
                        bin2dec('1101'), ...
                        BusDriver.PARAMETER.MPSSE_IO_DIRECTION_SPI];
                    
                    status = BusDriver.ftWrite(obj.ftHandle, opCode);
                    if status; return; end
                    
                    obj.headerRw = BusDriver.PARAMETER.MSB_FALLING_BYTE_IN_RISING_BYTE_OUT;
                    obj.headerR  = BusDriver.PARAMETER.MSB_FALLING_BYTE_IN;
                    obj.headerW  = BusDriver.PARAMETER.MSB_RISING_BYTE_OUT;
                    
                    obj.chipSelectEnable = [...
                        BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
                        bin2dec('0101'), ...
                        BusDriver.PARAMETER.MPSSE_IO_DIRECTION_SPI];
                    
                    obj.chipSelectDisable = [...
                        BusDriver.PARAMETER.MPSSE_SET_LOW_BYTE, ...
                        bin2dec('1101'), ...
                        BusDriver.PARAMETER.MPSSE_IO_DIRECTION_SPI];
                otherwise
                    status = 20; return;
            end
            
            %%% Compose "waint on interrupt" header, preamble
            switch obj.waitOnInterrupt
                case 0 %% Disable
                    obj.headerWaitIoState = [];
                case -1 %% Active Low
                    obj.headerWaitIoState = BusDriver.PARAMETER.MPSSE_WAIT_IO_LOW;
                case +1 %% Active High
                    obj.headerWaitIoState = BusDriver.PARAMETER.MPSSE_WAIT_IO_HIGH;
            end
            
            %% Initialization is done
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
            dataRx = zeros(size(dataTx(:)));
            
            numBytes = numel(dataTx);
            codedLength = double(typecast(uint16(numBytes)-1, 'uint8'));
            
            opCode = [obj.headerWaitIoState obj.chipSelectEnable obj.headerRw codedLength(1) codedLength(2) uint8(dataTx(:)') obj.chipSelectDisable BusDriver.PARAMETER.MPSSE_SEND_IMMEDIATE];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            numBytesToRead = numel(dataTx);
            [status, dataRxU8] = BusDriver.ftRead(obj.ftHandle, numBytesToRead);
            if status; return; end
            
            dataRx = double(dataRxU8);
        end
        
        function status = write(obj, dataTx)
            assert(obj.ftIsInitialized, 'Device not initialized')
            
            numBytes = numel(dataTx);
            codedLength = double(typecast(uint16(numBytes)-1, 'uint8'));
            
            opCode = [obj.headerWaitIoState obj.chipSelectEnable obj.headerW codedLength(1) codedLength(2) uint8(dataTx(:)') obj.chipSelectDisable BusDriver.PARAMETER.MPSSE_SEND_IMMEDIATE];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
        end
        
        function [dataRx, status] = read(obj, numBytesToRead)
            assert(obj.ftIsInitialized, 'Device not initialized')
            dataRx = zeros(numBytesToRead, 1);
            
            %%% Send out clocked dummy data in order to read in dataRx
            codedLength = double(typecast(uint16(numBytesToRead)-1, 'uint8'));
            
            opCode = [obj.headerWaitIoState obj.chipSelectEnable obj.headerR codedLength(1) codedLength(2) obj.chipSelectDisable BusDriver.PARAMETER.MPSSE_SEND_IMMEDIATE];
            status = BusDriver.ftWrite(obj.ftHandle, opCode);
            if status; return; end
            
            [status, dataRxU8] = BusDriver.ftRead(obj.ftHandle, numBytesToRead);
            if status; return; end
            
            dataRx = double(dataRxU8);
        end
    end
end