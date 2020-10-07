package com.craigl.esp8266punyforthloader;

import jssc.*;

/*
 * This class must implement the method serialEvent, through which we learn about 
 * events that happened to our port. In this case the arrival of the data.
 */

public class SerialPortReader implements SerialPortEventListener {

	// Class constructor
	public SerialPortReader(SerialPort port, CircularBuffer cb) {

		// Save incoming
		_port = port;
		_cb = cb;
	}

	public void serialEvent(SerialPortEvent event) {

		if (event.isRXCHAR()) {
			// Check if data is available
			if (event.getEventValue() >= 1) {
				// Data is available so write it to the Circular Buffer
				try {
					byte [] byteArray = _port.readBytes();
					for (int i = 0; i < byteArray.length; i++) {
						byte b = byteArray[i];
						_cb.write(b);
					}
				}
				catch (SerialPortException ex) {
					System.out.println(ex);
				}
			}
		}
	}

	// Private data
	CircularBuffer _cb;
	SerialPort _port;
}
