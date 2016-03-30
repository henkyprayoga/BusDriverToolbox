% Application Note AN_002, version 1.0.0

function AN_002(devId)
%% Initialize the interface
H = HUart();            % Returns a GPIO object, H, to read and write via UART
H.deviceNumber = devId; % Must be 0 if only one device / channel is attached. Otherwise use 1, 2 etc.
H.clock_Hz = 12e6;      % HINT - Baudrate 12MHz is the unique feature compared to virtual com port!
    
%% Open the device and check status
status = H.open();
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform write/read and check status
dataTx = 'Hello BusDriver!';
[dataRx, status] = H.writeRead(dataTx);
if status; error(BusDriver.ERROR_CODES{status}); end

disp(char(dataRx'))

%% Measure bandwidth - we reach ~1 MByte/s
dataTx = round(rand(10240, 1)*255);

tic;
for idx = 1:100; H.writeRead(dataTx); end
elapsedTimeWrite_s = toc;

disp(['Elapsed time for trasnfering 1.0240 Mbyte = ', num2str(elapsedTimeWrite_s)]);

%% Close the device and check status
status = H.close();
if status; error(BusDriver.ERROR_CODES{status}); end
