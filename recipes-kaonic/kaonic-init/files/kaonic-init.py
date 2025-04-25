
import os
import hashlib

SERIAL_FILE = "/etc/kaonic_serial"
HOSTAPD_CONF = "/etc/hostapd.conf"
OTP_NVMEM_FILE = "/sys/bus/nvmem/devices/stm32-romem0/nvmem"

def base32_encode(data: bytes) -> str:
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    bits = 0
    value = 0
    output = []

    for byte in data:
        value = (value << 8) | byte
        bits += 8
        while bits >= 5:
            index = (value >> (bits - 5)) & 0x1F
            output.append(alphabet[index])
            bits -= 5

    if bits > 0:
        index = (value << (5 - bits)) & 0x1F
        output.append(alphabet[index])

    return ''.join(output)

# https://wiki.stmicroelectronics.cn/stm32mpu/wiki/STM32MP15_resources#Reference_manuals
def read_otp(word:int, size:int) -> bytes:
    result = b"\xFF" * size
    try:
        with open(OTP_NVMEM_FILE, "rb") as f:
            f.seek(word * 4)
            result = f.read(size)
    except (FileNotFoundError, PermissionError, OSError) as e:
        print(f"failed to read OTP: {e}")

    return result

def parse_production_date(data: bytes) -> str:
    if len(data) != 4:
        raise ValueError("Expected 4 bytes")

    raw = int.from_bytes(data, byteorder='little')

    year = (raw >> 16) & 0xFFF
    week = (raw >> 8) & 0x3F
    day  = (raw >> 0) & 0x3F

    date = f"{year}{week:02}{day:02}"

    return date

def create_serial() -> str:

    uid = read_otp(13, 12).hex()
    print(f"STM32 UID: {uid}")

    production_date = read_otp(60, 4)
    production_date = parse_production_date(production_date)

    print(f"Production date: {production_date}")

    hashable = f"{production_date}|{uid}"
    hash = hashlib.sha256(hashable.encode()).digest()
    print(f"Hash: {hash.hex()}")
    encoded = base32_encode(hash).upper()
    encoded = encoded[:16]

    serial = f"{production_date}-{encoded}"
    print(f"Generated new serial: {serial}")

    return serial

def update_hostapd_conf(ssid:str):
    with open(HOSTAPD_CONF, "a") as f:
        f.write(f"\nssid={ssid}\n")

def save_serial(serial: str):

    with open(SERIAL_FILE, "w") as f:
        f.write(serial)

def main():
    # TODO: check hash
    if os.path.exists(SERIAL_FILE):
        return

    serial = create_serial()

    update_hostapd_conf(f"Kaonic /{serial.split('-')[1]}/")

    save_serial(serial)

if __name__ == "__main__":
    main()
