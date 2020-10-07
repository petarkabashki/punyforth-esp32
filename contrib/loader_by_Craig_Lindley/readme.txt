ESP8266PunyForthLoader Running Instructions
Craig A. Lindley
January 2017

Prerequisites
====================
1. ESP8266PunyForthLoader.jar
2. jssc.jar (version 2.6.0 or newer)

Executing From Shell
====================
1. Change directory to where the Punyforth jar files are located 
2. export FORTH_HOME=<“full path to directory with esp8266punyforth project files>”
3. export CLASSPATH=“./ESP8266PunyForthLoader.jar:./jssc.jar”
4. java com.craigl.esp8266punyforthloader.ESP8266PunyForthLoader

Alternatively add the following to your .profile file in your home directory
====================
# Items for ESP8266PunyForthLoader for ESP8266
export FORTH_HOME=~/Documents/dev/ESP8266PunyForthLoader/projects
export CLASSPATH=~/Documents/dev/ESP8266PunyForthLoader/ESP8266PunyForthLoader.jar:~/Documents/dev/ESP8266PunyForthLoader/jssc.jar
alias pfl="java com.craigl.esp8266punyforthloader.ESP8266PunyForthLoader"

Operation
====================
1. Connect your ESP8266Forth device to your computer
2. Execute ESP8266PunyForthLoader as described above
3. Once loader is operational, select appropriate Serial Port from drop down list
4. Click Open button in the UI to open the selected Serial Port
5. Type #help into the Input Area to see the help info
6. Type ESP8266PunyForth commands to interact with ESP8266PunyForth
7. Type #include <filename> to load Forth code from a file
8. Use up/down cursor keys to retrieve command history
9. Type #bye to terminate ESP8266PunyForthLoader


NOTES:
1. ESP8266PunyForthLoader’s window can be resized as necessary
