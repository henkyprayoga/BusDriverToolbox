% Application Note AN_001, version 1.0.0

function levelGet = AN_001(devId)
%% Initialize the interface
H = HGpio();            % Returns a GPIO object, H, to eighter drive or sense certain I/O-Pins
H.deviceNumber = devId; % Must be 0 if only one device / channel is attached. Otherwise use 1, 2 etc.
H.direction = [...      % Sets the direction for (A/B)DBUS 0:7 to either HGpio.IN or HGpio.OUT
    HGpio.IN ...        % D0
    HGpio.IN ...        % D1
    HGpio.IN ...        % D2
    HGpio.IN ...        % D3
    HGpio.OUT ...       % D4
    HGpio.OUT ...       % D5
    HGpio.OUT ...       % D6
    HGpio.OUT];         % D7
H.clock_Hz = 3e6;       % Set clock rate to 3MHz (max frequency)
H.timeout_ms = 3000;    % Set the read/write timeout to 3000ms

%% Open the device and check status
status = H.open();
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform write and check status
levelSet = [...         % Set the level for (A/B)DBUS 0:7 to either HGpio.LOW or HGpio.HIGH
    HGpio.LOW ...       % D0 - Will have no effect, since pin is defined as HGpio.IN
    HGpio.LOW ...       % D1 - Will have no effect, since pin is defined as HGpio.IN
    HGpio.LOW ...       % D2 - Will have no effect, since pin is defined as HGpio.IN
    HGpio.LOW ...       % D3 - Will have no effect, since pin is defined as HGpio.IN
    HGpio.HIGH ...      % D4
    HGpio.HIGH ...      % D5
    HGpio.LOW ...       % D6
    HGpio.LOW];         % D7

status = H.write(levelSet);
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform read and check status - here we will see what was written before due to the hardwired loopback
[levelGet, status] = H.read();
if status; error(BusDriver.ERROR_CODES{status}); end

%% Measure execution time - we are quite snappy with ~125µs transaction time for a single write or read
tic;
for i=1:1000; H.write(levelSet); end
elapsedTimeWrite_s = toc;
disp(['Elapsed time for 1000 writes /sec = ', num2str(elapsedTimeWrite_s)]);

tic;
for i=1:1000; H.read(); end
elapsedTimeWrite_s = toc;
disp(['Elapsed time for 1000 reads  /sec = ', num2str(elapsedTimeWrite_s)]);

%% Close the device and check status
status = H.close();
if status; error(BusDriver.ERROR_CODES{status}); end