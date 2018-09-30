#define MAX_ADDR_OFFSET      0x20
#define TWI_START 			 0x50000000

#define SM_GPIO_REG_CONTROL  0x00
#define SM_GPIO_REG_ADDR_C   0x04
#define SM_GPIO_REG_ADDR_R   0x08
#define SM_GPIO_REG_DATA_I   0x0C
#define SM_GPIO_REG_DATA_O   0x10

#define CHIP_ADDR            0x50
#define REG_ADDR             0x01
#define DATA_TR              0xAA
#define WR                   0x01
#define RD                   0x02



            .text

init:       move    $t0, $0              # t0 = 0
            li      $t0, TWI_START       # t0 = TWI_CONTROL_REG_A
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_ADDR_C
            move    $v0, $0              # int a = 0;
config_twi:
            # write chip_addr
            li		$v0, CHIP_ADDR
            sw      $v0, 0x0 ($t0)       # mem[i] = a;
            # write reg_addr
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_ADDR_R
            li		$v0, REG_ADDR
            sw      $v0, 0x0 ($t0)       # mem[i] = a;
            # write data_transmit
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_DATA_I
            li		$v0, DATA_TR
            sw      $v0, 0x0 ($t0)       # mem[i] = a;
            # write data_control         
            move    $t0, $0              # t0 = 0
            li      $t0, TWI_START       # t0 = TWI_CONTROL_REG_A
            li		$v0, WR
            # Start twi transfer
            sw      $v0, 0x0 ($t0)       # mem[i] = a;
            li      $v1, 0x00
            # Waiting for the end of the transfer write
wait1:
            lw      $v0, 0x0 ($t0)       # a = mem[i];
            bne     $v0, $v1, wait1      # if (i != max) goto write
            li		$v0, RD
            sw      $v0, 0x0 ($t0)       # mem[i] = a;
            # Waiting for the end of the transfer read
wait2:
            lw      $v0, 0x0 ($t0)       # a = mem[i];
            bne     $v0, $v1, wait2      # if (i != max) goto write
            li		$v0, 0x00
            move    $t0, $0              # t0 = 0
            li      $t0, TWI_START       # t0 = TWI_CONTROL_REG_A
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_ADDR_C
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_ADDR_R
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_DATA_I
            addiu   $t0, $t0, 4          # t0 = SM_GPIO_REG_DATA_O
            lw      $v0, 0x0 ($t0)       # mem[i] = a;
            lw      $v0, 0x0 ($t0)       # mem[i] = a;
end:
            b       end                  # while(1);
