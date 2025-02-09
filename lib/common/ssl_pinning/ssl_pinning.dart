import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SSLPinning {
  static Future<http.Client> get _instance async =>
      _clientInstance ??= await createLEClient();

  static http.Client? _clientInstance;
  static http.Client get client => _clientInstance ?? http.Client();

  static Future<void> init() async {
    _clientInstance = await _instance;
  }

  static Future<HttpClient> customHttpClient({
    bool isTestMode = false,
  }) async {
    SecurityContext context = SecurityContext(withTrustedRoots: false);
    try {
      List<int> bytes = [];

      if (isTestMode) {
        bytes = utf8.encode(_certificateString);
      } else {
        bytes = (await rootBundle.load('assets/certificates.pem')).buffer.asUint8List();
      }
      log('Successfully access and load certificate.pem file!');
      context.setTrustedCertificatesBytes(bytes);
    } on TlsException catch (e) {
      if (e.osError?.message != null && e.osError!.message.contains('CERT_ALREADY_IN_HASH_TABLE')) {
        log('createHttpClient() - cert already trusted! Skipping.');
      } else {
        log('createHttpClient().setTrustedCertificateBytes EXCEPTION: $e');
        rethrow;
      }
    } catch (e) {
      log('unexpected error $e');
      rethrow;
    }
    HttpClient httpClient = HttpClient(context: context);
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => false;

    return httpClient;
  }

  static Future<http.Client> createLEClient({bool isTestMode = false}) async {
    IOClient client = IOClient(await customHttpClient(isTestMode: isTestMode));
    return client;
  }
}

const _certificateString = """-----BEGIN CERTIFICATE-----
MIIF2zCCBMOgAwIBAgIQCoVsIwoArDevEGZIVZsZVDANBgkqhkiG9w0BAQsFADA8
MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRwwGgYDVQQDExNBbWF6b24g
UlNBIDIwNDggTTAxMB4XDTIzMDIyMzAwMDAwMFoXDTIzMTAxODIzNTk1OVowGzEZ
MBcGA1UEAwwQKi50aGVtb3ZpZWRiLm9yZzCCASIwDQYJKoZIhvcNAQEBBQADggEP
ADCCAQoCggEBANQOhd2TCirITiFP5YTB/np0qmVAbiMrcg3t13qH4BZTlQBMwS7j
q2nuwBr/8zZTEVfnYSyebsvt6IdQjizfFd3LDtXMkCkQE66I0hGRbUnXYcR5dC2C
HeuTE0ZLeNlYfIwP0rJaA6L/SpCo4JCnuTCdfS2QkEGfXcSpdUE3xjnCDa5YK81f
u46nMGmhHhsHNhGB+x2PRxz8DFOlYzWYUjBpr+hJIjM48KIGyK55IT53I1PWuzX9
+Y8hCcQmah+JcCqWh4ezhEuDBN0JybnNAXtt+5zXGpk8B9w4sqShd8N6zKNHCxOM
KE06Pc0/tntcAxseky7YY2N6o5uuN21I+tECAwEAAaOCAvgwggL0MB8GA1UdIwQY
MBaAFIG4DmOKiRIY5fo7O1CVn+blkBOFMB0GA1UdDgQWBBTx0VmTK8/zl5mNJbdv
v9wIUvYunjArBgNVHREEJDAighAqLnRoZW1vdmllZGIub3Jngg50aGVtb3ZpZWRi
Lm9yZzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUF
BwMCMDsGA1UdHwQ0MDIwMKAuoCyGKmh0dHA6Ly9jcmwucjJtMDEuYW1hem9udHJ1
c3QuY29tL3IybTAxLmNybDATBgNVHSAEDDAKMAgGBmeBDAECATB1BggrBgEFBQcB
AQRpMGcwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vY3NwLnIybTAxLmFtYXpvbnRydXN0
LmNvbTA2BggrBgEFBQcwAoYqaHR0cDovL2NydC5yMm0wMS5hbWF6b250cnVzdC5j
b20vcjJtMDEuY2VyMAwGA1UdEwEB/wQCMAAwggF9BgorBgEEAdZ5AgQCBIIBbQSC
AWkBZwB2AK33vvp8/xDIi509nB4+GGq0Zyldz7EMJMqFhjTr3IKKAAABhn6p4zsA
AAQDAEcwRQIgdNNjNLBOg3tQH6Xj7OIS4c2yiOrLpYXwniJ8GwZpP18CIQDXJ0PL
xCrhGOB7iPY6hXRie83kGcZjDYRpHo6gaUnypAB1ALNzdwfhhFD4Y4bWBancEQlK
eS2xZwwLh9zwAw55NqWaAAABhn6p4yoAAAQDAEYwRAIgBNRx6sfLBMoDxXigYnBq
1URIu/uD41gpeTcLFCVHEboCIEnR2tepXct7q59pTlaEG5KLEr0C2tRf4lpJ0wZP
12cDAHYAtz77JN+cTbp18jnFulj0bF38Qs96nzXEnh0JgSXttJkAAAGGfqnjBwAA
BAMARzBFAiBDABwqD/RywJiaN2bp//MiRlPNPL7vkg3gaFXqcGmmogIhAJNfE/AI
KkgcOY/1uX/jLl1BsUFPLZKpNeMmCJYeKgQ9MA0GCSqGSIb3DQEBCwUAA4IBAQCc
ZMcsFM61a8YhtbRIIfmvnBJi4VtEyZ1SY7FAD3Uv61ZX3M0RTKeFAN8e4riUClAH
d3b+d5YnvSrvP1nHraveNmJg2M9yxBtsm/dZ6Q6EBO0TdYc19F2G8Oddyth5TPNi
wR2h/VEguHh6HeeAmD59okVnyOi5CymaM8xkLO/12fagIOEMuERQq2n+YZ9AWvTn
1Gyny1Y/Tcyt6jauLpMsVBrSLPWvLWT/PBL87TX106E3k8IAMDM4F1vG+EFk09FT
DJvR70AALzDvhhFNPnz2J498BEYXm2LixxQhOfG4N7U89bl7gz/i1v3XslaAQx8h
Q8V+Pm7ggCU74+18i++m
-----END CERTIFICATE-----""";