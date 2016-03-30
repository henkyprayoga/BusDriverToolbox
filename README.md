**Schedule** – *BusDriver* lets you interface MATLAB® directly to ICs performing analog and digital I/O. You can sense data for analysis and visualisation, generate data for control and test automation or even close the loop by inserting some fancy computations in between. It offers build-in support on high level abstraction for: 

* GPIO, [AN_001](#an_001-interfacing-matlab-to-ics-via-gpio)
* UART, [AN_002](#an_002-interfacing-matlab-to-ics-via-uart)
* SPI,  [AN_003](#an_003-interfacing-matlab-to-ics-via-spi)
* I2C,  [AN_004](#an_004-interfacing-matlab-to-ics-via-i2c)

**Shift up a gear** – *BusDriver* supports MATLAB code generation capabilities to get your products real more quickly within a single tool chain. *BusDriver* is your powerfull companion driving you from rapid prototyping to series product development in no time.

**Ticket Check** – *BusDriver* is released under commercial and [GNU GPL v.2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) open source licenses. Once your project becomes commercialised GPLv2 licensing dictates that you need to either open your source fully or purchase a commercial license. DspKitchen offer commercial licenses without any GPL restrictions. [Contact us for pricing](https://github.com/dspKitchen).

## **Next Stop** – Geeting Started with *BusDriver*

1. Start up MATLAB (Recommended is R2016a, but older versions will probably work fine)
2. Downlaod and install the *BusDriver* Toolbox from within MATLAB

	```
	>> websave(filename,url)
	```
	
3. Plug in a [supported USB-to-serial converter](#supported-usb-to-serial-converter), e.g.
	* Mikroelektronika [click USB adapter](http://www.mikroe.com/click/usb-adapter/) (**Recommended** due to its superior choice of ready to use [click boards™](http://www.mikroe.com/click/))
	* Adafruit [FT232H Breakout](https://www.adafruit.com/products/2264) (**Hint** – This board is quite cheep)
	* FTDI [FT232H M232H-B](http://www.ftdichip.com/Products/Modules/DevelopmentModules.htm#UM232H-B) 	
	* FTDI [FT2232H mini module](http://www.ftdichip.com/Products/Modules/DevelopmentModules.htm#FT2232H_Mini)
	* FTDI [FT4232H mini module](http://www.ftdichip.com/Products/Modules/DevelopmentModules.htm#FT4232H_Mini) (**Hint** – For all those who operate up to 4 ICs in parallel)
4. Check whether your USB-to-serial converter is recognised by *BusDriver*	

	```
	>> BusDriver.getDevices()
	
	ans =
	
	[              0]    [              1]
	'Dual RS232-HS A'    'Dual RS232-HS B'
	'A'                  'B'              
	[              2]    [              2]
	[              6]    [              6]
	[       67330064]    [       67330064]
	[         202017]    [         202018]
	```
	
5. You have done it - the engine runs fine! Now, attach an IC of choise to the USB-to-serial converter and let *BusDriver* hit the road.

## Itinerary – On how to go with *BusDriver* 
#### AN_001 *Interfacing MATLAB to ICs via GPIO*
Connect the pins and execute the file *AN_001.m* as follows
* ADBUS0 (D0) and ADBUS4 (D4), notably hardwired loopback of D0 and D4
* ADBUS1 (D1) and ADBUS5 (D5), notably hardwired loopback of D1 and D5
* ADBUS2 (D2) and ADBUS6 (D6), notably hardwired loopback of D2 and D6
* ADBUS3 (D3) and ADBUS7 (D7), notably hardwired loopback of D3 and D7

```
>> deviceId = 0;
>> AN_001(deviceId)
Elapsed time for 1000 writes /sec = 0.16505
Elapsed time for 1000 reads  /sec = 0.18014

ans =

     1     1     0     0     1     1     0     0
```
	
And here goes the code ... 
```matlab
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
```

#### AN_002 *Interfacing MATLAB to ICs via UART*
Connect the pins and execute the file *AN_002.m* as follows
* ADBUS0 (D0) and ADBUS1 (D1), notably hardwired loopback of RX and TX

```
>> deviceId = 0;
>> AN_002(deviceId)
Hello BusDriver!
Elapsed time for loop around 1.0240 Mbyte = 0.97171
```
And here goes the code ... 

```matlab
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
```

#### AN_003 *Interfacing MATLAB to ICs via SPI*
Connect the pins and execute the file *AN_003.m* as follows
* ADBUS1 (D1) and ADBUS2 (D2), notably hardwired loopback of MISO and MOSI

```
>> deviceId = 0;
>> AN_003(deviceId)
Hello BusDriver!
Elapsed time/s for transferring 1.0240 Mbyte: 0.35617
```
And here goes the code ... 

```matlab
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
```

#### AN_004 *Interfacing MATLAB to ICs via I2C*
Connect the pins to a real device (loopback is not possible) and execute the file *AN_004.m* as follows
* ADBUS0 (D0) and Slave IC SCL
* ADBUS1 (D1) and ADBUS2 (D2) and Slave IC SDA

```
>> deviceId = 0;
>> AN_004(deviceId)
   123

Elapsed time/s for 1000 writes: 0.53617
Elapsed time/s for 1000 reads:  0.65904
```

And here goes the code ... 
```
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
```

## Under the Hood – USB-to-serial converter
Any FTDI USB-to-serial converter with one of the follwoing  ICs is supported by *BusDriver*:

* [FT232H](http://www.ftdichip.com/Products/ICs/FT232H.htm), 1-channel 
* [FT2232H](http://www.ftdichip.com/Products/ICs/FT2232H.htm), 2-channels 
* [FT4232H](http://www.ftdichip.com/Products/ICs/FT4232H.htm), 4-channels
