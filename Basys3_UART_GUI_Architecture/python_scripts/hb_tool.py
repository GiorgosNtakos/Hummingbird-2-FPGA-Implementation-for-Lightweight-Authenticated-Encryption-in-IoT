import serial
import time
import hb2_validation

COM_PORT = "COM3"
BAUDRATE = 115200

last_ciphertext = None
last_mac_tag = None


# --------------------------------------------------
# FLAGS
# --------------------------------------------------

def build_flags(operation, integrity, verify_mac):

    flags = 0

    flags |= (operation << 0)
    flags |= (integrity << 1)
    flags |= (verify_mac << 2)

    return flags


# --------------------------------------------------
# BUILD PACKET
# --------------------------------------------------

def build_packet(
        operation,
        integrity,
        verify_mac,
        text_len,
        key_hex,
        iv_hex,
        data_hex,
        mac_hex):

    packet = bytearray()

    packet.append(
        build_flags(
            operation,
            integrity,
            verify_mac
        )
    )

    packet.append(text_len)

    packet += bytes.fromhex(key_hex)
    packet += bytes.fromhex(iv_hex)
    packet += bytes.fromhex(data_hex)
    packet += bytes.fromhex(mac_hex)

    return packet


# --------------------------------------------------
# FPGA COMMAND
# --------------------------------------------------

def run_command(
        ser,
        operation,
        integrity,
        verify_mac,
        text_len,
        key_hex,
        iv_hex,
        data_hex,
        mac_hex):

    packet = build_packet(
        operation,
        integrity,
        verify_mac,
        text_len,
        key_hex,
        iv_hex,
        data_hex,
        mac_hex
    )

    ser.write(packet)

    response = ser.read(35)

    if len(response) != 35:
        raise RuntimeError(
            f"Expected 35 bytes, got {len(response)}"
        )

    data_output = response[0:16]
    mac_tag = response[16:32]
    mac_valid = response[32]
    
    latency_cycles = (
        (response[33] << 8)
        |
        response[34]
    )

    return (
        data_output.hex().upper(),
        mac_tag.hex().upper(),
        mac_valid,
        latency_cycles
    )


# --------------------------------------------------
# INPUT HELPERS
# --------------------------------------------------

def get_hex(prompt, expected_length):

    while True:

        value = input(prompt).strip().upper()

        if len(value) != expected_length:
            print(
                f"Expected {expected_length} hex characters"
            )
            continue

        try:
            bytes.fromhex(value)
            return value

        except ValueError:
            print("Invalid hex string")


def get_text_length():

    while True:

        try:

            value = int(
                input(
                    "Text Length (1-128): "
                )
            )

            if 1 <= value <= 128:
                return value

        except:
            pass

        print("Invalid length")


def get_integrity():

    while True:

        value = input(
            "Integrity (0/1): "
        ).strip()

        if value in ["0", "1"]:
            return int(value)

        print("Enter 0 or 1")


# --------------------------------------------------
# ENCRYPT
# --------------------------------------------------

def encrypt_menu(ser):

    global last_ciphertext
    global last_mac_tag

    print()
    print("------------ ENCRYPT ------------")

    key = get_hex(
        "Key (32 hex chars): ",
        32
    )

    iv = get_hex(
        "IV (16 hex chars): ",
        16
    )

    data = get_hex(
        "Data (32 hex chars): ",
        32
    )

    text_len = get_text_length()

    integrity = get_integrity()

    ciphertext, mac_tag, _ = run_command(
        ser,

        operation=0,
        integrity=integrity,
        verify_mac=0,

        text_len=text_len,

        key_hex=key,
        iv_hex=iv,

        data_hex=data,

        mac_hex=
        "00000000000000000000000000000000"
    )

    last_ciphertext = ciphertext
    last_mac_tag = mac_tag

    print()
    print("Ciphertext:")
    print(ciphertext)

    print()
    print("MAC Tag:")
    print(mac_tag)


# --------------------------------------------------
# DECRYPT
# --------------------------------------------------

def decrypt_menu(ser):

    global last_ciphertext
    global last_mac_tag

    print()
    print("------------ DECRYPT ------------")

    key = get_hex(
        "Key (32 hex chars): ",
        32
    )

    iv = get_hex(
        "IV (16 hex chars): ",
        16
    )

    text_len = get_text_length()

    integrity = get_integrity()

    use_previous = input(
        "Use previous ciphertext/mac (Y/N): "
    ).strip().upper()

    if (
        use_previous == "Y"
        and
        last_ciphertext is not None
        and
        last_mac_tag is not None
    ):

        ciphertext = last_ciphertext
        mac_tag = last_mac_tag

    else:

        ciphertext = get_hex(
            "Ciphertext (32 hex chars): ",
            32
        )

        mac_tag = get_hex(
            "MAC Tag (32 hex chars): ",
            32
        )

    plaintext, _, mac_valid = run_command(
        ser,

        operation=1,
        integrity=integrity,
        verify_mac=1,

        text_len=text_len,

        key_hex=key,
        iv_hex=iv,

        data_hex=ciphertext,

        mac_hex=mac_tag
    )

    print()
    print("Plaintext:")
    print(plaintext)

    print()

    if mac_valid == 1:
        print("MAC VALID")
    else:
        print("MAC INVALID")


# --------------------------------------------------
# VALIDATION SUITE
# --------------------------------------------------

def validation_suite(ser):

    print()
    print("Running Validation Suite...")
    print()

    hb2_validation.run_validation_suite(ser)

# --------------------------------------------------
# MAIN
# --------------------------------------------------

def main():

    ser = serial.Serial(
        port=COM_PORT,
        baudrate=BAUDRATE,
        bytesize=8,
        parity='N',
        stopbits=1,
        timeout=5
    )

    time.sleep(1)

    while True:

        print()
        print("================================")
        print("HB2 FPGA TOOL")
        print("================================")
        print("1. Encrypt")
        print("2. Decrypt")
        print("3. Run Validation Suite")
        print("4. Exit")
        print()

        choice = input(
            "Choice: "
        ).strip()

        try:

            if choice == "1":

                encrypt_menu(ser)

            elif choice == "2":

                decrypt_menu(ser)

            elif choice == "3":

                validation_suite(ser)

            elif choice == "4":

                break

            else:

                print("Invalid option")

        except Exception as e:

            print()
            print("ERROR:")
            print(e)

    ser.close()


if __name__ == "__main__":
    main()