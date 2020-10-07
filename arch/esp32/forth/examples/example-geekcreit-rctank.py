# This is pygame based, remote gamepad controller for nodemcu rc tank
# https://github.com/zeroflag/punyforth/blob/master/arch/esp8266/forth/examples/example-geekcreit-rctank.forth
# Tested with Python2.7 pygame-1.9.2a0 with a Genius Maxfire 12 usb gamepad

import pygame, socket

class Tank:
    directions = {        
        (0, -1) : b'F',
        (0, 1)  : b'B',
        (-1, 0) : b'L',
        (1, 0)  : b'R',
        (0, 0)  : b'S'
    }    
    def __init__(self, address):
        self.address = address
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.engine_started = False
        
    def move(self, direction):
        if direction in Tank.directions:
            self._command(Tank.directions[direction])

    def speedup(self): self._command(b'I')
    def slowdown(self): self._command(b'D')
    def toggle_lamp(self): self._command(b'T')
    def auto_pilot(self): self._command(b'A')
    
    def toggle_engine(self):
        self._command(b'H' if self.engine_started else b'E')
        self.engine_started = not self.engine_started
        
    def _command(self, cmd):
        print('Sending command %s to: %s' % (cmd, self.address))
        self.socket.sendto(cmd, self.address)

class Gamepad:
    def __init__(self, joystick, horizontal_axis, vertical_axis, button_config):
        pygame.init()
        pygame.joystick.init()        
        self.joystick = pygame.joystick.Joystick(joystick)
        self.button_config = button_config
        self.horizontal_axis, self.vertical_axis = horizontal_axis, vertical_axis        
        self.joystick.init()
        print("Joystick %s initialized" % self.joystick.get_name())
        
    def control(self, robot):        
        while True:
            for event in pygame.event.get():
                direction = [self.joystick.get_axis(self.horizontal_axis), self.joystick.get_axis(self.vertical_axis)]
                robot.move(tuple(map(round, direction)))
                if self._button_down('engine'):
                    robot.toggle_engine()
                elif self._button_down('lamp'):
                    robot.toggle_lamp()
            if self._button_down('speed+'):
                robot.speedup()
            elif self._button_down('speed-'):
                robot.slowdown()
            elif self._button_down('auto-pilot'):
                robot.auto_pilot()

    def _button_down(self, name):
        return self.joystick.get_button(self.button_config[name]) == 1

if __name__ == '__main__':
    gamepad = Gamepad(
        joystick=0, 
        horizontal_axis=0, 
        vertical_axis=1, 
        button_config={
            'engine': 0, 
            'speed+': 5, 
            'speed-': 7, 
            'lamp' : 4,
            'auto-pilot' : 3
        })
    gamepad.control(Tank(('192.168.0.22', 8000)))
