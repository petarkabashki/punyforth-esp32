package com.craigl.esp8266punyforthloader;

import java.util.ArrayList;
import java.util.concurrent.TimeUnit;

import jssc.*;

/*
 * Finite state machine for interacting with CForth host
 */
public class FSM {

	private static final String ENTER_KEY = "\r\n";

	enum MAIN_STATES {
		INIT, SEND_CHK, DELAY, RECV_CHK
	};

	enum SUB_STATES {
		ST1, ST2, ST3, ST4, ST5, ST6, ST7, ST8
	};

	// Class constructor
	public FSM(CircularBuffer cb, TextOutputIntfc out, CmdListStatusIntfc intfc) {

		// Save incoming
		_port = null;
		_cb = cb;
		_out = out;
		_intfc = intfc;

		// Set initial state of FSM
		state = MAIN_STATES.INIT;

		// Set initial state of sub FSM
		subState = SUB_STATES.ST1;
	}

	public void setSerialPort(SerialPort port) {
		_port = port;
	}

	public void clearCmdList() {
		cmdList.clear();
	}
	
	// Submit a forth command that will be executed at the proper time
	public void submitCmd(String cmd) {

		// Trim up command string
		cmd.trim();

		cmd += ENTER_KEY;

		// Add cmd to the list of possible other commands
		cmdList.add(cmd);
	}

	// Run the finite state machine for CForth interaction
	public void runFSM() {

		while (true) {

			switch (state) {

			case INIT:

				// Indicate a cmd can be sent
				okFound = true;

				compiling = false;
				prevByte = 0;

				// Set initial state of state machine
				state = MAIN_STATES.SEND_CHK;

				break;

			case SEND_CHK:

				if (okFound && (cmdList.size() != 0)) {

					// Cmd can be sent so fetch the oldest to execute
					String cmd = cmdList.remove(0);

					// End FSM execution
					if (cmd.indexOf("!bye_bye!") != -1) {
						return;
					}

					// Check for start of compilation
					if (cmd.startsWith(":")) {
						compiling = true;
					}

					// Check for end of compilation
					if (cmd.endsWith(";")) {
						compiling = false;
					}
					try {
						// Write the cmd to the serial port
						_port.writeString(cmd);

						// Output the cmd to terminal
						_out.outputText(cmd);

					} catch (SerialPortException e) {
						e.printStackTrace();
					}

					// Can't send another cmd until Puny Forth says it's OK
					okFound = false;

					// Is the cmd list now empty ?
					if (cmdList.size() == 0) {
						// Yes, signal the event
						_intfc.cmdListEmpty();

					}
				}
				// Set next state
				state = MAIN_STATES.DELAY;
				break;

			case DELAY:

				try {
					TimeUnit.MILLISECONDS.sleep(1);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}

				// Set next state
				state = MAIN_STATES.RECV_CHK;
				break;

			case RECV_CHK:

				// Are there received bytes to process ?
				if (!_cb.isEmpty()) {

					// Yes there are
					byte b = _cb.read();

					// Output the character
					_out.outputText("" + ((char) b));

					// Are we in a multi line definition ?
					if ((b == '.') && (prevByte == '.') && (_cb.peek() == ' ') && compiling) {
						okFound = true;

					} else {

						switch (subState) {
						case ST1:
							// Do we have an opening paren ?
							if (b == '(') {
								subState = SUB_STATES.ST2;
							}
							break;

						case ST2:
							// Do we have an s ?
							if (b == 's') {
								subState = SUB_STATES.ST3;
							} else {
								subState = SUB_STATES.ST1;
							}
							break;

						case ST3:
							// Do we have a t ?
							if (b == 't') {
								subState = SUB_STATES.ST4;
							} else {
								subState = SUB_STATES.ST1;
							}
							break;

						case ST4:
							// Do we have an a ?
							if (b == 'a') {
								subState = SUB_STATES.ST5;
							} else {
								subState = SUB_STATES.ST1;
							}
							break;

						case ST5:
							// Do we have a c ?
							if (b == 'c') {
								subState = SUB_STATES.ST6;
							} else {
								subState = SUB_STATES.ST1;
							}
							break;

						case ST6:
							// Do we have a k ?
							if (b == 'k') {
								subState = SUB_STATES.ST7;
							} else {
								subState = SUB_STATES.ST1;
							}
							break;

						case ST7:
							// We have (stack so ignore all chars until closing
							// paren
							if (b == ')') {
								subState = SUB_STATES.ST8;
							}
							break;

						case ST8:
							// Do we have a space ?
							if (b == ' ') {
								// Start the state machine over
								subState = SUB_STATES.ST1;

								// Indicate we are ready for the next command
								okFound = true;
							}
							break;
						}
					}
					// Save previous byte
					prevByte = b;
				}
				// Set next state
				state = MAIN_STATES.SEND_CHK;
				break;
			}
		}
	}

	// Private data
	SerialPort _port;
	CircularBuffer _cb;
	TextOutputIntfc _out;
	CmdListStatusIntfc _intfc;

	MAIN_STATES state;
	SUB_STATES subState;
	ArrayList<String> cmdList = new ArrayList<String>();
	int arrayListIndex;
	boolean okFound, compiling;
	byte prevByte;
}
