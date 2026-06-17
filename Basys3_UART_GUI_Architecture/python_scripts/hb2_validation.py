import serial
import time

# --------------------------------------------------
# FLAGS
# bit0 = operation
# bit1 = integrity
# bit2 = verify_mac
# --------------------------------------------------

def build_flags(operation, integrity, verify_mac):

    flags = 0

    flags |= (operation  << 0)
    flags |= (integrity  << 1)
    flags |= (verify_mac << 2)

    return flags


# --------------------------------------------------
# BUILD UART PACKET
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

    # byte 0
    packet.append(
        build_flags(
            operation,
            integrity,
            verify_mac
        )
    )

    # byte 1
    packet.append(text_len)

    # key (16 bytes)
    packet += bytes.fromhex(key_hex)

    # iv (8 bytes)
    packet += bytes.fromhex(iv_hex)

    # data (16 bytes)
    packet += bytes.fromhex(data_hex)

    # received mac (16 bytes)
    packet += bytes.fromhex(mac_hex)

    return packet


# --------------------------------------------------
# SEND COMMAND TO FPGA
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

    print()
    print("Sending packet...")
    print("Packet Length =", len(packet))

    ser.write(packet)

    response = ser.read(35)

    print("Received", len(response), "bytes")

    if len(response) != 35:
        raise RuntimeError(
            f"Expected 35 bytes but got {len(response)}"
        )

    data_output = response[0:16]
    mac_tag     = response[16:32]
    mac_valid   = response[32]
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
# MAIN
# --------------------------------------------------

def run_validation_suite(ser):
    results = []

    print("--------------------------------")
    print("HB2 UART TEST")
    print("--------------------------------")

    # ==================================================
    # TEST VECTOR 1
    # ENCRYPTION
    # ==================================================

    print()
    print("TEST VECTOR 1 - ENCRYPTION")

    ciphertext, mac_tag, mac_valid, latency_cycles = run_command(
        ser,

        operation=0,
        integrity=0,
        verify_mac=0,

        text_len=128,

        key_hex=
        "23016745AB89EFCDDCFE98BA54761032",

        iv_hex=
        "34127856BC9AF0DE",

        data_hex=
        "11003322554477669988BBAADDCCFFEE",

        mac_hex=
        "00000000000000000000000000000000"
    )

    print()
    print("Ciphertext =", ciphertext)
    print("MAC Tag    =", mac_tag)
    print("MAC Valid  =", mac_valid)
    print("Latency Cycles =", latency_cycles)

    expected_ciphertext = (
        "D15BADF81423F420"
        "B1BAC2542945383D"
    )

    if ciphertext == expected_ciphertext:
        results.append(
            ("TEST VECTOR 1", "PASS")
        )
    else:
        results.append(
            ("TEST VECTOR 1", "FAIL")
        )
        print("Expected =", expected_ciphertext)

    # ==================================================
    # TEST VECTOR 2
    # DECRYPTION
    # ==================================================

    print()
    print("TEST VECTOR 2 - DECRYPTION")

    plaintext, mac_tag_2, mac_valid_2, latency_cycles = run_command(
        ser,

        operation=1,
        integrity=0,
        verify_mac=1,

        text_len=128,

        key_hex=
        "23016745AB89EFCDDCFE98BA54761032",

        iv_hex=
        "34127856BC9AF0DE",

        data_hex=ciphertext,

        mac_hex=mac_tag
    )

    print()
    print("Plaintext  =", plaintext)
    print("MAC Tag    =", mac_tag_2)
    print("MAC Valid  =", mac_valid_2)
    print("Latency Cycles =", latency_cycles)

    expected_plaintext = (
        "1100332255447766"
        "9988BBAADDCCFFEE"
    )

    if plaintext == expected_plaintext:
         results.append(
            ("TEST VECTOR 2", "PASS")
        )
    else:
        results.append(
            ("TEST VECTOR 2", "FAILED")
        )
        print("Expected =", expected_plaintext)

    if mac_valid_2 == 1:
        print("MAC VERIFICATION PASSED")
    else:
        print("MAC VERIFICATION FAILED")
        
    # ==================================================
    # TEST VECTOR 3
    # STREAM CIPHER ENCRYPTION
    # ==================================================

    print()
    print("TEST VECTOR 3 - STREAM CIPHER ENCRYPTION")

    ciphertext3, mac_tag3, mac_valid3, latency_cycles = run_command(
        ser,

        operation=0,
        integrity=0,
        verify_mac=0,

        text_len=13,

        key_hex=
        "00000000000000000000000000000000",

        iv_hex=
        "0000000000000000",

        data_hex=
        "00000000000000000000000000000000",

        mac_hex=
        "00000000000000000000000000000000"
    )

    print()
    print("Ciphertext =", ciphertext3)
    print("MAC Tag    =", mac_tag3)
    print("MAC Valid  =", mac_valid3)
    print("Latency Cycles =", latency_cycles)

    expected_ciphertext3 = (
        "0000000000000000"
        "0000000000000FC4"
    )

    if ciphertext3 == expected_ciphertext3:
         results.append(
            ("TEST VECTOR 3", "PASS")
        )
    else:
        results.append(
            ("TEST VECTOR 3", "FAILED")
        )
        print("Expected =", expected_ciphertext3)
    
    # ==================================================
    # TEST VECTOR 4
    # STREAM CIPHER DECRYPTION
    # ==================================================

    print()
    print("TEST VECTOR 4 - STREAM CIPHER DECRYPTION")

    plaintext4, mac_tag4, mac_valid4, latency_cycles = run_command(
        ser,

        operation=1,
        integrity=0,
        verify_mac=1,

        text_len=13,

        key_hex=
        "00000000000000000000000000000000",

        iv_hex=
        "0000000000000000",

        data_hex=ciphertext3,

        mac_hex=mac_tag3
    )

    print()
    print("Plaintext =", plaintext4)
    print("MAC Tag   =", mac_tag4)
    print("MAC Valid =", mac_valid4)
    print("Latency Cycles =", latency_cycles)

    expected_plaintext4 = (
        "0000000000000000"
        "0000000000000000"
    )

    if plaintext4 == expected_plaintext4:
         results.append(
            ("TEST VECTOR 4", "PASS")
        )
    else:
        results.append(
            ("TEST VECTOR 4", "FAILED")
        )
        print("Expected =", expected_plaintext4)

    if mac_valid4 == 1:
        print("MAC VERIFICATION PASSED")
    else:
        print("MAC VERIFICATION FAILED")
        
    # ==================================================
    # TEST VECTOR 5
    # INTEGRITY MODE ENCRYPTION
    # ==================================================

    print()
    print("TEST VECTOR 5 - INTEGRITY ENCRYPTION")

    ciphertext5, mac_tag5, mac_valid5, latency_cycles = run_command(
        ser,

        operation=0,
        integrity=1,
        verify_mac=0,

        text_len=83,

        key_hex=
        "23016745AB89EFCDDCFE98BA54761032",

        iv_hex=
        "34127856BC9AF0DE",

        data_hex=
        "11003322554477669988BBAADDCCFFEE",

        mac_hex=
        "00000000000000000000000000000000"
    )

    print()
    print("Ciphertext =", ciphertext5)
    print("MAC Tag    =", mac_tag5)
    print("MAC Valid  =", mac_valid5)
    print("Latency Cycles =", latency_cycles)
    
    expected_ciphertext5 = (
        "00000000438DDCA5"
        "0B3BB87AD8CD0004"
    )
    
    if ciphertext5 == expected_ciphertext5:
         results.append(
            ("TEST VECTOR 5", "PASS")
        )
    else:
        results.append(
            ("TEST VECTOR 5", "FAILED")
        )
        print("Expected =", expected_ciphertext5)
    
    # ==================================================
    # TEST VECTOR 6
    # INTEGRITY MODE DECRYPTION
    # ==================================================

    print()
    print("TEST VECTOR 6 - INTEGRITY DECRYPTION")

    plaintext6, mac_tag6, mac_valid6, latency_cycles = run_command(
        ser,

        operation=1,
        integrity=1,
        verify_mac=1,

        text_len=83,

        key_hex=
        "23016745AB89EFCDDCFE98BA54761032",

        iv_hex=
        "34127856BC9AF0DE",

        data_hex=ciphertext5,

        mac_hex=mac_tag5
    )

    print()
    print("Plaintext =", plaintext6)
    print("MAC Tag   =", mac_tag6)
    print("MAC Valid =", mac_valid6)
    print("Latency Cycles =", latency_cycles)
    
    expected_plaintext6 = (
        "0000000055447766"
        "9988BBAADDCC0006"
    )

    if plaintext6 == expected_plaintext6:
         results.append(
            ("TEST VECTOR 6", "PASS")
        )
    else:
        results.append(
            ("TEST VECTOR 6", "FAILED")
        )
        print("Expected =", expected_plaintext6)

    if mac_valid6 == 1:
        print("MAC VERIFICATION PASSED")
    else:
        print("MAC VERIFICATION FAILED")
    
    return results


# --------------------------------------------------

if __name__ == "__main__":

    ser = serial.Serial(
        port=COM_PORT,
        baudrate=BAUDRATE,
        bytesize=8,
        parity='N',
        stopbits=1,
        timeout=5
    )

    time.sleep(1)

    run_validation_suite(ser)

    ser.close()