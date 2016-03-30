% Application Note AN_004, version 1.0.0

function AN_004(devId)
H = HI2cMaster();       % Returns a I2C object, H, to read from and write to
H.deviceNumber = devId; % Must be 0 if only one device / channel is attached. Otherwise use 1, 2 etc.
H.slaveAddress7Bit = 64;% Must be the 7Bit I2C-slave address
H.clock_Hz = 100e3;     % Set clock rate to 100kHz (Normalmode)
H.timeout_ms = 3000;    % Set the read/write timeout to 3000ms

%% Open the device and check status
status = H.open();
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform write and check status
register = 0; % arbitrary register
dataTx = 123; % Dummy data
status = H.write(register, dataTx);
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform read and check status - here we will see what was written before
numBytesToRead = 1;
[dataRx, status] = H.read(register, numBytesToRead);
if status; error(BusDriver.ERROR_CODES{status}); end
disp(dataRx);

%% Measure execution time - we are quite snappy with ~600µs transaction time for a single write or read
% Throughput could be further increased by writing/reading multiple bytes at once,
% when register auto increment is supported by your slave.
tic;
for i=1:1000; H.write(register, dataTx); end
elapsedTimeWrite_s = toc;
disp(['Elapsed time/s for 1000 writes: ', num2str(elapsedTimeWrite_s)]);

tic;
for i=1:1000; H.read(register, numBytesToRead); end
elapsedTimeWrite_s = toc;
disp(['Elapsed time/s for 1000 reads:  ', num2str(elapsedTimeWrite_s)]);

%% Close the device and check status
status = H.close();
if status; error(BusDriver.ERROR_CODES{status}); end