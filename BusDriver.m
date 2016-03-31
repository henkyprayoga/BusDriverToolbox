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

classdef BusDriver
    properties (Constant = true)
        %%% parameter, defined in ftd2xx.h
        PARAMETER = struct(...
            'DO_NOT_CARE',      0, ...
            ...
            'FT_BITS_7',        7, ...
            'FT_BITS_8',        8, ...
            ...
            'FT_STOP_BITS_1',   0, ...
            'FT_STOP_BITS_2',   2, ...
            ...
            'FT_PARITY_NONE',   0, ...
            'FT_PARITY_ODD',    1, ...
            'FT_PARITY_EVEN',   2, ...
            'FT_PARITY_MARK',   3, ...
            'FT_PARITY_SPACE',  4, ...
            ...
            'FT_FLOW_NONE',     0, ...
            'FT_FLOW_RTS_CTS',  256, ...
            'FT_FLOW_DTR_DSR',  512, ...
            'FT_FLOW_XON_XOFF', 1024, ...
            ...
            'FT_PURGE_RX',      1, ...
            'FT_PURGE_TX',      2, ...
            ...
            'FT_BITMODE_RESET',         0, ...
            'FT_BITMODE_ASYNC_BITBANG', 1, ...
            'FT_BITMODE_MPSSE',         2, ...
            'FT_BITMODE_SYNC_BITBANG',  4, ...
            'FT_BITMODE_MCU_HOST',      8, ...
            'FT_BITMODE_FAST_SERIAL',   16, ...
            'FT_BITMODE_CBUS_BITBANG',  32, ...
            'FT_BITMODE_SYNC_FIFO',     64, ...
            ...
            'MPSSE_SET_LOW_BYTE',               hex2dec('80'), ...
            'MPSSE_LOOPBACK_ENABLE',            hex2dec('84'), ...
            'MPSSE_LOOPBACK_DISABLE',           hex2dec('85'), ...
            'MPSSE_CLOCK_DEVISOR',              hex2dec('86'), ...
            'MPSSE_SEND_IMMEDIATE',             hex2dec('87'), ...
            'MPSSE_WAIT_IO_HIGH',               hex2dec('88'), ...
            'MPSSE_WAIT_IO_LOW',                hex2dec('89'), ...
            ...
            'MPSSE_60MHZ_CLOCK',                hex2dec('8A'), ...
            'MPSSE_ENABLE_3_PHASE_CLOCKING',    hex2dec('8C'), ...
            'MPSSE_DISABLE_3_PHASE_CLOCKING',   hex2dec('8D'), ...
            'MPSSE_DISABLE_ADAPTIVE_CLOCKING',  hex2dec('97'), ...
            'MPSSE_BOGUS_COMMAND',              hex2dec('AB'), ...
            'MPSSE_BAD_COMMAND',                hex2dec('FA'), ...
            ...
            'MPSSE_IO_DIRECTION_SPI',           bin2dec('0000 1011'), ... %% 0: Input; 1: Output
            'MPSSE_IO_DIRECTION_I2C_WRITE',     bin2dec('0000 0011'), ... %% 0: Input; 1: Output
            'MPSSE_IO_DIRECTION_I2C_READ',      bin2dec('0000 0001'), ... %% 0: Input; 1: Output
            ...
            'MSB_RISING_BYTE_OUT',                  hex2dec('10'), ...
            'MSB_FALLING_BYTE_OUT',                 hex2dec('11'), ...
            'MSB_RISING_BIT_OUT',                   hex2dec('12'), ...
            'MSB_FALLING_BIT_OUT',                  hex2dec('13'), ...
            'MSB_RISING_BYTE_IN',                   hex2dec('20'), ...
            'MSB_FALLING_BYTE_IN',                  hex2dec('24'), ...
            'MSB_RISING_BIT_IN',                    hex2dec('22'), ...
            'MSB_FALLING_BIT_IN',                   hex2dec('26'), ...
            'MSB_RISING_BYTE_IN_FALLING_BYTE_OUT',  hex2dec('31'), ...
            'MSB_FALLING_BYTE_IN_RISING_BYTE_OUT',  hex2dec('34'), ...
            'MSB_RISING_BIT_IN_FALLING_BIT_OUT',    hex2dec('33'), ...
            'MSB_FALLING_BIT_IN_RISING_BIT_OUT',    hex2dec('36') ...
            );
        
        %%% error codes, defined in ftd2xx.h
        ERROR_CODES = {...
            'FT_INVALID_HANDLE'; ...                1
            'FT_DEVICE_NOT_FOUND'; ...              2
            'FT_DEVICE_NOT_OPENED'; ...             3
            'FT_IO_ERROR'; ...                      4
            'FT_INSUFFICIENT_RESOURCES'; ...        5
            'FT_INVALID_PARAMETER'; ...             6
            'FT_INVALID_BAUD_RATE'; ...             7
            'FT_DEVICE_NOT_OPENED_FOR_ERASE'; ...   8
            'FT_DEVICE_NOT_OPENED_FOR_WRITE'; ...   9
            'FT_FAILED_TO_WRITE_DEVICE'; ...        10
            'FT_EEPROM_READ_FAILED'; ...            11
            'FT_EEPROM_WRITE_FAILED'; ...           12
            'FT_EEPROM_ERASE_FAILED'; ...           13
            'FT_EEPROM_NOT_PRESENT'; ...            14
            'FT_EEPROM_NOT_PROGRAMMED'; ...         15
            'FT_INVALID_ARGS'; ...                  16
            'FT_NOT_SUPPORTED'; ...                 17
            'FT_OTHER_ERROR'; ...                   18
            'FT_DEVICE_LIST_NOT_READY'; ...         19
            'BUSDRIVER_UNEXPECTED_DATA' ...         20
            };
    end
    
    methods (Static)
        %% several functions, definded in ftd2xx.h
        function [status, ftHandle] = ftOpen(deviceId)
            if coder.target('MATLAB')
                ftHandle = libpointer('uint32Ptr', 0);
                status = calllib('d2xx', 'FT_Open', deviceId, ftHandle);
            else
                ftHandle = coder.opaque('FT_HANDLE', '0');
                status = -1; %#ok
                status = coder.ceval('FT_Open', deviceId, coder.wref(ftHandle));
            end
        end
        
        function status = ftResetDevice(handle)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_ResetDevice', handle);
            else
                status = -1; %#ok
                status = coder.ceval('FT_ResetDevice', handle);
            end
        end
        
        function [status, numBytesToRead] = ftGetQueueStatus(handle)
            if coder.target('MATLAB')
                numBytesToReadPtr = libpointer('uint32Ptr', 0);
                status = calllib('d2xx', 'FT_GetQueueStatus', handle, numBytesToReadPtr);
                numBytesToRead = numBytesToReadPtr.Value;
            else
                numBytesToReadPtr = coder.opaque('DWORD', '0');
                status = -1; %#ok
                status = coder.ceval('FT_GetQueueStatus', handle, coder.wref(numBytesToReadPtr));
                numBytesToRead = double(numBytesToReadPtr);
            end
        end
        
        function status = ftSetUsbParameters(handle, inTransferSize, outTransferSize)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetUSBParameters', handle, inTransferSize, outTransferSize);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetUSBParameters', handle, inTransferSize, outTransferSize);
            end
        end
        
        function status = ftSetChars(handle, eventCharacter, eventCharacterEnabled, errorCharacter, errorCharacterEnabled)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetChars', handle, eventCharacter, eventCharacterEnabled, errorCharacter, errorCharacterEnabled);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetChars', handle, eventCharacter, eventCharacterEnabled, errorCharacter, errorCharacterEnabled);
            end
        end
        
        function status = ftClrRts(handle)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_ClrRts', handle);
            else
                status = -1; %#ok
                status = coder.ceval('FT_ClrRts', handle);
            end
        end
        
        function status = ftSetBaudRate(handle, baudRate)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetBaudRate', handle, baudRate);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetBaudRate', handle, baudRate);
            end
        end
        
        function status = ftSetDataCharacteristics(handle, wordLength, stopBits, parity)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetDataCharacteristics', handle, wordLength, stopBits, parity);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetDataCharacteristics', handle, wordLength, stopBits, parity);
            end
        end
        
        function status = ftSetFlowControl(handle, flowControl, xOn, xOff)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetFlowControl', handle, flowControl, xOn, xOff);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetFlowControl', handle, flowControl, xOn, xOff);
            end
        end
        
        function status = ftSetTimeouts(handle, readTimeout, writeTimeout)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetTimeouts', handle, readTimeout, writeTimeout);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetTimeouts', handle, readTimeout, writeTimeout);
            end
        end
        
        function status = ftSetLatencyTimer(handle, timeout)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetLatencyTimer', handle, timeout);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetLatencyTimer', handle, timeout);
            end
        end
        
        function status = ftSetBitMode(handle, mask, mode)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_SetBitMode', handle, mask, mode);
            else
                status = -1; %#ok
                status = coder.ceval('FT_SetBitMode', handle, mask, mode);
            end
        end
        
        function [status, mode] = ftGetBitMode(handle)
            if coder.target('MATLAB')
                modePtr = libpointer('uint8Ptr', 0);
                status = calllib('d2xx', 'FT_GetBitMode', handle, modePtr);
                mode = double(modePtr.Value);
            else
                modePtr = zeros(1, 1, 'uint8');
                
                status = -1; %#ok
                status = coder.ceval('FT_GetBitMode', handle, coder.ref(modePtr));
                mode = double(modePtr);
            end
        end
        
        function  [status, dataRx, bytesRead] = ftRead(handle, numBytesToRead)
            if coder.target('MATLAB')
                dataRxPtr = libpointer('uint8Ptr', zeros(numBytesToRead, 1));
                bytesReadPtr = libpointer('uint32Ptr', 0);
                
                status = calllib('d2xx', 'FT_Read', handle, dataRxPtr, numBytesToRead, bytesReadPtr);
                dataRx = dataRxPtr.Value;
                bytesRead = bytesReadPtr.Value;
            else
                dataRxPtr = zeros(numBytesToRead, 1, 'uint8');
                bytesReadPtr = coder.opaque('DWORD', '0');
                
                status = -1; %#ok
                status = coder.ceval('FT_Read', handle, coder.ref(dataRxPtr), numBytesToRead, coder.wref(bytesReadPtr));
                dataRx = double(dataRxPtr);
                bytesRead = double(bytesReadPtr);
            end
        end
        
        function status = ftWrite(handle, dataTx)
            if coder.target('MATLAB')
                dataTxPtr = libpointer('uint8Ptr', uint8(dataTx));
                bytesWrittenPtr = libpointer('uint32Ptr', 0);
                status = calllib('d2xx', 'FT_Write', handle, dataTxPtr, numel(dataTx), bytesWrittenPtr);
            else
                dataTxUint8 = uint8(dataTx);
                dataTxUint8 = [dataTxUint8 0];
                
                bytesWritten = coder.opaque('DWORD', '0');
                status = -1; %#ok
                status = coder.ceval('FT_Write', handle, coder.rref(dataTxUint8), uint16(numel(dataTx)), coder.wref(bytesWritten));
            end
        end
        
        function status = ftPurge(handle, mask)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_Purge', handle, mask);
            else
                status = -1; %#ok
                status = coder.ceval('FT_Purge', handle, mask);
            end
        end
        
        function status = ftClose(handle)
            if coder.target('MATLAB')
                status = calllib('d2xx', 'FT_Close', handle);
            else
                status = -1; %#ok
                status = coder.ceval('FT_Close', handle);
            end
        end
        
        %% helper functions
        function loadLibrary
            global d2xxCount
            if coder.target('MATLAB')
                if isempty(d2xxCount) || (d2xxCount == 0)
                    loadlibrary('ftd2xx64.dll', @ftd2xx, 'alias', 'd2xx');
                    d2xxCount = 1;
                else
                    d2xxCount = d2xxCount + 1;
                end
            end
        end
        
        function unloadLibrary
            global d2xxCount
            if coder.target('MATLAB')
                if ~isempty(d2xxCount) && (d2xxCount > 0)
                    d2xxCount = d2xxCount - 1;
                    if  (d2xxCount == 0)
                        unloadlibrary('d2xx')
                    end
                end
            end
        end
        
        function [deviceTable, status] = getDevices()
            assert(coder.target('MATLAB'), 'Not available from without MATLAB')
            BusDriver.loadLibrary();
            
            totalDevicesPtr = libpointer('uint32Ptr', 0);
            status = calllib('d2xx', 'FT_CreateDeviceInfoList', totalDevicesPtr);
            if status; return; end;
            
            warningId = 'MATLAB:table:RowsAddedExistingVars';
            warning('off', warningId)
            
            totalDevices = totalDevicesPtr.Value;
            deviceNumber = cell(totalDevices, 1);
            deviceTable = table;
            
            for deviceIdx = 0:totalDevices-1
                flags           = libpointer('uint32Ptr', 0);
                type            = libpointer('uint32Ptr', 0);
                id              = libpointer('uint32Ptr', 0);
                locId           = libpointer('uint32Ptr', 0);
                serialNumber    = libpointer('uint8Ptr', zeros(1,16, 'uint8'));
                description     = libpointer('uint8Ptr', zeros(1,64, 'uint8'));
                handle          = libpointer('uint32Ptr',0);
                
                status = calllib('d2xx', 'FT_GetDeviceInfoDetail', ...
                    deviceIdx, flags, type, id, locId, serialNumber, description, handle);
                if status; return; end;
                
                deviceNumber{deviceIdx+1} = num2str(deviceIdx);
                deviceTable.Description{deviceIdx+1, 1}     = char(description.Value(1:find(description.Value==0, 1, 'first') - 1)); %%% NULL-Terminated String;
                deviceTable.SerialNumber{deviceIdx+1, 1}    = char(serialNumber.Value(1:find(serialNumber.Value==0, 1, 'first') - 1)); %%% NULL-Terminated String
                deviceTable.Flag(deviceIdx+1, 1)            = uint32(flags.Value);
                deviceTable.Type(deviceIdx+1, 1)            = uint32(type.Value);
                deviceTable.ID(deviceIdx+1, 1)              = uint32(id.Value);
                deviceTable.LocationID(deviceIdx+1, 1)      = uint32(locId.Value);
            end
            warning('on', warningId)
            
            deviceTable.Properties.RowNames = deviceNumber;
            
            BusDriver.unloadLibrary();
        end
        
        function [deviceNumber, status] = getDeviceNumber(deviceDescription)
            [deviceTable, status] = BusDriver.getDevices();
            deviceNumber = find(ismember(deviceTable.Description, deviceDescription))-1;
        end
    end
end