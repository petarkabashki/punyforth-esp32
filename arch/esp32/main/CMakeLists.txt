idf_component_register(SRCS 

                        "forth_evt.c"
                        # "forth_i2c.c"
                        # # "forth_netconn.c"
                        "forth_time.c"
                        "forth_flash.c"
                        "forth_io.c"
                        # "forth_spi.c"
                        # # "forth_wifi.c"
                        "forth_gpio.c"
                        "forth_math.c"
                        "forth_sys.c"
                        # # "forth_ws2812.c"
                        "punyforth.S"

                        "user_main.c"
                        # "punn.c"
                    INCLUDE_DIRS ".")


# Create a SPIFFS image from the contents of the 'spiffs_image' directory
# that fits the partition named 'storage'. FLASH_IN_PROJECT indicates that
# the generated image should be flashed when the entire project is flashed to
# the target with 'idf.py -p PORT flash'. 
# spiffs_create_partition_image(storage ../spiffs_image FLASH_IN_PROJECT)

