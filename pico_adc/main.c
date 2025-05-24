#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "hardware/adc.h"
#include "hardware/spi.h"

#define MIN_ADC 0x650
#define MAX_ADC 0xD40

#define SPI_RX_PIN  10
#define SPI_TX_PIN  11
#define SPI_CS_PIN  13
#define SPI_SCK_PIN 10

uint8_t out_buf[32];
uint8_t in_buf[32];

int main() {
  stdio_init_all();
  printf("ADC Example, measuring GPIO26\n");

  // Make sure GPIO is high-impedance, no pullups etc

  spi_init(spi1, 1000 * 1000);
  spi_set_slave(spi1, true);
  gpio_set_function(SPI_RX_PIN, GPIO_FUNC_SPI);
  gpio_set_function(SPI_SCK_PIN, GPIO_FUNC_SPI);
  gpio_set_function(SPI_TX_PIN, GPIO_FUNC_SPI);
  gpio_set_function(SPI_CS_PIN, GPIO_FUNC_SPI);

  adc_init();

  adc_gpio_init(28);
  adc_select_input(2);

  while (1) {
    const float conversion_factor = 3.3f / (1 << 12);
    uint16_t result = adc_read();

    out_buf[0] = result & 0xFF;
    out_buf[1] = (result >> 8) & 0xFF;

    printf("Raw value: 0x%03x, humidity: %f%% \n", result, (1.0f -(result-(float)MIN_ADC)/((float)MAX_ADC-(float)MIN_ADC))*100);

    spi_write_read_blocking(spi1, out_buf, in_buf, 2);
  }

  return 0;
}
