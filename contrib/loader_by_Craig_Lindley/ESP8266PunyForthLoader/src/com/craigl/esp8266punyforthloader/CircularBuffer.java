package com.craigl.esp8266punyforthloader;

import java.util.Arrays;

public class CircularBuffer {

	private byte data[];
	private int head;
	private int tail;

	public CircularBuffer(int bufferSize) {
		data = new byte[bufferSize];
		head = 0;
		tail = 0;
	}

	public synchronized void clear() {		
		head = 0;
		tail = 0;
		Arrays.fill(data, (byte) 0);
	}
	public synchronized boolean write(byte value) {
		if (! isFull()) {
			data[tail++] = value;
			if (tail == data.length) {
				tail = 0;
			}
			return true;
		} else {
			return false;
		}
	}

	public synchronized byte read() {
		if (head != tail) {
			byte value = data[head++];
			if (head == data.length) {
				head = 0;
			}
			return value;
		} else {
			return 0;
		}
	}

	public synchronized byte peek() {
		if (head != tail) {
			Byte value = data[head];
			return value.byteValue();
		} else {
			return 0;
		}
	}

	public boolean isEmpty() {
		return (head == tail);
	}

	public boolean isFull() {
		if (tail + 1 == head) {
			return true;
		}
		if (tail == (data.length - 1) && head == 0) {
			return true;
		}
		return false;
	}
}
