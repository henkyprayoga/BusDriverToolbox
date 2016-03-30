% Application Note AN_003, version 1.0.0

function AN_003(devId)
H = HSpiMaster();       % Returns a SPI object, H, to read from and write to
H.deviceNumber = devId; % Must be 0 if only one device / channel is attached. Otherwise use 1, 2 etc.
H.spiMode = 0;          % Can be either 0 (CPOL=0, CPHA=0) or 2 (CPOL=1, CPHA=0)
H.clock_Hz = 30e6;      % Set clock rate to 30MHz (max frequency)
H.timeout_ms = 3000;    % Set the read/write timeout to 3000ms

%% Open the device and check status
status = H.open();
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform write/read and check status
dataTx = 'Hello BusDriver!';
[dataRx, status] = H.writeRead(dataTx);
if status; error(BusDriver.ERROR_CODES{status}); end

disp(char(dataRx'))

%% Measure bandwidth - we reach ~3 MByte/s
dataTx = round(rand(10240, 1)*255);

tic;
for idx = 1:100; H.writeRead(dataTx); end
elapsedTimeWrite_s = toc;

disp(['Elapsed time/s for transferring 1.0240 Mbyte: ', num2str(elapsedTimeWrite_s)]);

%% Close the device and check status
status = H.close();
if status; error(BusDriver.ERROR_CODES{status}); end
