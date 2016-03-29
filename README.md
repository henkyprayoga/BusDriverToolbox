*BusDriver* lets you interface MATLAB® directly to ICs performing analoge and digital I/O. You can sense data for analysis and visualisation, generate data for control and test automation or even close the loop by inserting some fancy computations in between. It offers build-in support on high level abstraction for: 

* GPIO
* UART
* SPI
* I2C
* *Parallel Interfaces are comming soon ...*

To shift up a gear: *BusDriver* supports MATLAB code generation capabilities to get your products real more quickly within a single tool chain. *BusDriver* is your powerfull companion driving you from rapid prototyping to series product development in no time.

NEXT STOP: *BusDriver* is licensed under BSD 2-Clause License.

## Geeting Started
1. Start up MATLAB (Recommended is R2016a, but older versions will probably work fine)
2. Downlaod and install the *BusDriver*-Library from within MATLAB
	
	```matlab
	>> websave(filename,url)
	```

3. Plug in a supported USB-to-serial converter, e.g.
	* 2-channel Mikroelektronika [click USB adapter](http://www.mikroe.com/click/usb-adapter/) (**Recommended due to its superior choice of ready to use [click boards™](http://www.mikroe.com/click/)**)
	* 1-channel Adafruit [FT232H Breakout](https://www.adafruit.com/products/2264) (This board is quite cheep)
	* 1-channel original [FT232H M232H-B](http://www.ftdichip.com/Products/Modules/DevelopmentModules.htm#UM232H-B) 	
	* 2-channel original [FT2232H mini module](http://www.ftdichip.com/Products/Modules/DevelopmentModules.htm#FT2232H_Mini)
	* 4-channel original [FT4232H mini module](http://www.ftdichip.com/Products/Modules/DevelopmentModules.htm#FT4232H_Mini) (For all those who operate up to 4 ICs in parallel)
4. Check whether your FTDI-chip is recognised by *BusDriver*	
		
	```matlab
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
	
5. You have done it - the engine runs fine! Now, attach an IC of choise to the FDTI-chip and let *BusDriver* hit the road.

## Application Notes
### AN_001 *Interfacing MATLAB to ICs via GPIO*
Ground ADBUS1 (D1) and execute the function *AN_001* as follows
```matlab
>> deviceId = 0;
>> AN_001(deviceId)

ans =

1     0     1     1     1     1     1     1
```
	
And here goes the code ... 
```matlab
% Application Note AN_001, version 1.0.0

function levelGet = AN_001(devId)
%% Initialize the Interface
H = HGpio();            % Returns a GPIO object, H, to eighter drive or sense certain I/O-Pins
H.deviceNumber = devId; % Must be 0 if only one device / channel is attached. Otherwise use 1, 2 etc.
H.direction = [...      % Sets the direction for (A/B)DBUS 0:7 to either HGpio.IN or HGpio.OUT
	HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN HGpio.IN];
H.clock_Hz = 9600;      % Set clock rate to 9600 Hz
H.timeout_ms = 3000;    % Set the read/write timeout to 3000ms

%% Open the device and check status
status = H.open();
if status; error(BusDriver.ERROR_CODES{status}); end

%% Perform read and write (exactly this order) and check status
levelSet = [...         % Set the level for (A/B)DBUS 0:7 to either HGpio.LOW or HGpio.HIGH. Will have no effect, since als pins are defined as HGpio.IN
	HGpio.LOW HGpio.LOW HGpio.LOW HGpio.LOW HGpio.LOW HGpio.LOW HGpio.LOW HGpio.LOW];
	
[levelGet, status] = H.readWrite(levelSet);
if status; error(BusDriver.ERROR_CODES{status}); end

%% Close the device and check status
status = H.close();
if status; error(BusDriver.ERROR_CODES{status}); end
```

## Supported USB-to-serial converter
Any FTDI USB-to-serial converter with one of the follwoing  ICs:

* 1-channel [FT232H](http://www.ftdichip.com/Products/ICs/FT232H.htm)
* 2-channel [FT2232H](http://www.ftdichip.com/Products/ICs/FT2232H.htm)
* 4-channel [FT4232H](http://www.ftdichip.com/Products/ICs/FT4232H.htm)
