package com.craigl.esp8266punyforthloader;

import java.awt.*;
import java.awt.event.*;

import javax.swing.*;

import java.io.*;
import java.util.*;

import jssc.*;

import java.util.regex.Pattern;

public class ESP8266PunyForthLoader extends JPanel implements
		CmdListStatusIntfc {

	private static final long serialVersionUID = 1L;
	private static final String ENTER_KEY = "\r\n";

	private boolean processIncludeDirective(String cmd) {

		// Was it the include directive ?
		if (cmd.indexOf("#include") != -1) {
			int len = "#include ".length();
			String fn = cmd.substring(len);

			// Check for file existance before trying to read it
			File f = new File(path + fn);
			if (f.exists()) {

				// Create a buffered reader for the specified file
				FileInputStream fstream = null;
				try {
					fstream = new FileInputStream(path + fn);
				} catch (FileNotFoundException e) {
					e.printStackTrace();
				}
				// / Create buffered reader
				BufferedReader br = new BufferedReader(new InputStreamReader(
						fstream));

				// Push reader onto include file stack
				includeFileStack.push(br);
			} else {
				// Include file not found
				outputTextArea.append("ERROR: include file: \"" + path + fn
						+ "\" not found");
			}

			return true;
		} else {
			return false;
		}
	}

	// Called when cmd list in FSM goes empty
	public void cmdListEmpty() {

		// Is the include file stack not empty
		if (!includeFileStack.empty()) {

			// Get reader for include file if available from stack
			BufferedReader br = includeFileStack.peek();

			// Are we processing an include file ?
			if (br != null) {
				// Yes so attempt to read a line of the file
				String textLine = null;

				try {
					// Read a line of text from the include file
					textLine = br.readLine();

					// Have we reached EOF ?
					if (textLine != null) {
						// Remove extraneous white space
						textLine.trim();

						// Does the line have any content ?
						if (textLine.length() != 0) {
							// Yes the line has content

							// Is this a comment line ?
							if (textLine.startsWith("\\")) {
								// Yes so ignore it. Now submit an empty cmd so
								// FSM continues
								textLine = "";
							}

							// Is this an include file directive ?
							else if (processIncludeDirective(textLine)) {
								// Yes it was. Include file processed. Now
								// submit an empty cmd so FSM continues
								textLine = "";
							}
						}
						// Submit line to FSM
						fsm.submitCmd(textLine);

					} else {

						// EOF so close the include file
						br.close();

						// Pop include file off of include file stack
						includeFileStack.pop();

						// Submit empty cmd so FSM continues
						fsm.submitCmd("");
					}
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
	}

	// Open a serial port by port name
	private boolean openSerialPort(String portName) {

		// If a port is already open, close it
		if (serialPort != null) {
			try {
				serialPort.closePort();
			} catch (SerialPortException e) {
				e.printStackTrace();
			}
		}
		serialPort = null;
		portIsOpen = false;

		// Check for vaild port name
		if ((portName == null) || (portName.length() == 0)) {
			return false;
		}

		// Attempt to open the selected serial port
		serialPort = new SerialPort(portName);

		if (serialPort == null) {
			return false;
		}

		// Attempt to open the port
		try {
			// Open the selected serial port
			serialPort.openPort();
			serialPort.setParams(115200, 8, 1, 0);

			int mask = SerialPort.MASK_RXCHAR;// Prepare mask
			serialPort.setEventsMask(mask);// Set mask

			// Add listener for serial events
			serialPort.addEventListener(new SerialPortReader(serialPort, cb));
		} catch (SerialPortException e) {
			e.printStackTrace();
			return false;
		}

		// Signal all is well
		portIsOpen = true;
		return true;
	}

	// Close an open serial port
	private void closeSerialPort() {

		// Only attempt port close if port is open
		if (portIsOpen && (serialPort != null)) {
			try {
				serialPort.closePort();
			} catch (SerialPortException e) {
				e.printStackTrace();
			}
			serialPort = null;
			portIsOpen = false;
		}
	}

	// Build UI and Go
	public void run() {

		// Get the home directory for CForthLoader
		path = env.get("FORTH_HOME") + "/";

		// Indicate serial port is not yet open
		portIsOpen = false;

		// Get the available serial port names
		Pattern pattern = Pattern.compile("tty\\Q.\\E*");
		portNames = SerialPortList.getPortNames(pattern);

		// Create loader user interface

		// Create top panel
		JPanel topPanel = new JPanel();
		topPanel.setLayout(new GridLayout(1, 3));

		// Left label panel
		topPanel.add(new JLabel("Serial Config - 115200B/S : 8B : 1SB : N",
				JLabel.CENTER));

		// Port combo box is not user editable
		portComboBox.setEditable(false);

		// Add combo box to panel
		topPanel.add(portComboBox);

		// New panel for button
		JPanel buttonPanel = new JPanel();
		buttonPanel.setLayout(new GridLayout(1, 3));
		buttonPanel.add(new JPanel());

		// Add action listener to the open/close port button
		openClosePortButton.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent evt) {
				if ((!portIsOpen) && haveSerialPorts) {
					// Get what is selected in the combo box
					String portName = (String) portComboBox.getSelectedItem();

					if (!portName.equalsIgnoreCase("No Serial Ports found")) {
						// Attempt to open the port
						openSerialPort(portName);

						// Let the FSM know the serial port
						fsm.setSerialPort(serialPort);

						// Set button text
						openClosePortButton.setText("Close");

						// Enable text input and give it focus
						inputTextField.setEnabled(true);
						inputTextField.requestFocus();
					}
				} else {
					// Port was open so close it
					closeSerialPort();

					// Set button text
					openClosePortButton.setText("Open");

					// Disable text input
					inputTextField.setEnabled(false);
					
					// Clear the circular buffer
					cb.clear();
					
					// Clear command list
					fsm.clearCmdList();
				}
			}
		});

		// Add open/close button to panel
		buttonPanel.add(openClosePortButton);
		buttonPanel.add(new JPanel());
		topPanel.add(buttonPanel);

		// Create middle panel
		JPanel midPanel = new JPanel();
		midPanel.setLayout(new BorderLayout());

		// Create border around panel
		midPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

		JLabel label = new JLabel("--- Output Area ---", JLabel.CENTER);
		label.setBackground(Color.LIGHT_GRAY);
		label.setOpaque(true);
		label.setBorder(BorderFactory.createLineBorder(Color.black, 2));
		midPanel.add(label, BorderLayout.NORTH);

		// Define output text area
		outputTextArea.setEditable(false);
		midPanel.add(outputTextScrollPane, BorderLayout.CENTER);

		// Create bottom panel
		JPanel bottomPanel = new JPanel();
		bottomPanel.setLayout(new BorderLayout());

		label = new JLabel(
				"--- Input Area : Use up/down cursor keys for command history ---",
				JLabel.CENTER);
		label.setBackground(Color.LIGHT_GRAY);
		label.setOpaque(true);
		label.setBorder(BorderFactory.createLineBorder(Color.black, 2));

		bottomPanel.add(label, BorderLayout.NORTH);

		// Add action listener to input text field
		inputTextField.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent evt) {

				// Get what the user typed
				String cmd = inputTextField.getText().trim();

				// Don't add empty entries to the history list
				if (cmd.length() != 0) {
					// Record non-empty cmd in history list
					cmdHistoryList.add(cmd);
				}

				// Was it the include directive ?
				if (processIncludeDirective(cmd)) {
					cmd = "";
				}

				// Was it the clear directive ?
				else if (cmd.indexOf("#clear") != -1) {
					outputTextArea.setText("");
					cmd = "";
				}

				// Was it the help directive ?
				else if (cmd.indexOf("#help") != -1) {
					outputTextArea.setText("");
					outputTextArea
							.append("ESP8266PunyForthLoader by Craig A. Lindley\n");
					outputTextArea
							.append("\nESP8266PunyForthLoader Directives:\n\n");
					outputTextArea.append("#clear - Clears the Output Area\n");
					outputTextArea
							.append("#bye - Terminates ESP8266PunyForthLoader\n");
					outputTextArea.append("#help - Shows this message\n");
					outputTextArea
							.append("#include filename - Loads Forth code from a file\n");
					outputTextArea.append("\nNOTES:\n");
					outputTextArea
							.append("1. Remember to have your ESP8266 device connected before starting ESP8266PunyForthLoader\n");
					outputTextArea
							.append("2. Remember to set the FORTH_HOME environment variable if using include files\n");
					outputTextArea.append("3. #include files can be nested\n");
					outputTextArea
							.append("4. Use the up/down cursor keys to access command history\n");
					outputTextArea
							.append("\nQuestions/Comments to calhjh@gmail.com\n");

					cmd = "";
				}

				// Was it the exit directive ?
				else if (cmd.indexOf("#bye") != -1) {
					cmd = "!bye_bye!";
				}

				// Send it to the FSM
				fsm.submitCmd(cmd);

				// Clear text in field
				inputTextField.setText("");

				// Point index at final entry of history list
				cmdHistoryListIndex = cmdHistoryList.size() - 1;
			}
		});

		// Add a key listener to the input text field
		inputTextField.addKeyListener(new java.awt.event.KeyAdapter() {
			public void keyPressed(java.awt.event.KeyEvent evt) {

				// Get count of history list entries
				int count = cmdHistoryList.size();

				// Up arrow key ?
				if (evt.getKeyCode() == KeyEvent.VK_UP) {
					// Populate input area
					inputTextField.setText(cmdHistoryList
							.get(cmdHistoryListIndex));

					cmdHistoryListIndex--;
					if (cmdHistoryListIndex < 0) {
						cmdHistoryListIndex = 0;
					}
				}

				// Down arrow key ?
				if (evt.getKeyCode() == KeyEvent.VK_DOWN) {
					cmdHistoryListIndex++;
					if (cmdHistoryListIndex == count) {
						cmdHistoryListIndex = count - 1;
						inputTextField.setText("");
					} else {
						inputTextField.setText(cmdHistoryList
								.get(cmdHistoryListIndex));
					}
				}
			}
		});

		// Text field is initially disabled
		inputTextField.setEnabled(false);

		// Add text field to panel
		bottomPanel.add(inputTextField, BorderLayout.CENTER);

		// Create over all view
		setLayout(new BorderLayout());
		add(topPanel, BorderLayout.NORTH);
		add(midPanel, BorderLayout.CENTER);
		add(bottomPanel, BorderLayout.SOUTH);

		// Create and set up the display window.
		JFrame frame = new JFrame(
				"ESP8266 Puny Forth Loader - Craig A. Lindley - Version: 0.1");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		// Add content to the window.
		frame.add(this);

		// Display the window.
		frame.pack();
		frame.setVisible(true);

		// Are serial ports available ?
		haveSerialPorts = portNames.length != 0;

		// Populate combo box with serial ports, if any
		if (haveSerialPorts) {
			for (int i = 0; i < portNames.length; i++) {
				String pns = portNames[i];
				portComboBox.addItem(pns);
			}
		} else {
			portComboBox.addItem("No Serial Ports found");
		}

		// Create a circular buffer for the received serial data
		cb = new CircularBuffer(20000);

		// Instantiate FSM
		fsm = new FSM(cb, new TextOutputIntfc() {
			public void outputText(String t) {
				// Append the text
				outputTextArea.append(t);

				// Make sure the new text is visible
				outputTextArea.setCaretPosition(outputTextArea.getDocument()
						.getLength());
			}
		}, this);

		// Run the FSM
		fsm.runFSM();

		// Close the serial port
		closeSerialPort();

		// Terminate program
		System.exit(0);
	}

	// Private data
	boolean haveSerialPorts;
	String[] portNames;
	boolean portIsOpen;

	// References to custom class objects
	CircularBuffer cb = null;
	SerialPort serialPort = null;
	FSM fsm = null;

	// Environment variables map
	Map<String, String> env = System.getenv();
	String path;

	// Cmd history list
	ArrayList<String> cmdHistoryList = new ArrayList<String>();
	int cmdHistoryListIndex;

	// Include file stack
	Stack<BufferedReader> includeFileStack = new Stack<BufferedReader>();

	// Instantiate UI controls
	JComboBox<String> portComboBox = new JComboBox<String>();
	JButton openClosePortButton = new JButton("Open");
	JTextArea outputTextArea = new JTextArea(30, 60);
	JScrollPane outputTextScrollPane = new JScrollPane(outputTextArea,
			JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,
			JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
	JTextField inputTextField = new JTextField(30);

	// Program entry point
	public static void main(String[] args) {

		// Create app instance
		ESP8266PunyForthLoader app = new ESP8266PunyForthLoader();

		// Run it
		app.run();
	}
}
